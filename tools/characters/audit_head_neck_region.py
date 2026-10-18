"""Blender read-only region validation. Failed art checks remain failures.
-b --disable-autoexec AUTHORING.blend -P THIS -- PRIVATE_REGION_DIRECTORY
"""
import bpy,bmesh,json,math,sys
from pathlib import Path
from mathutils import Vector
root=Path(sys.argv[sys.argv.index('--')+1]).resolve()
m=json.loads((root/'manifest.json').read_text())
report={'production_ready':False,'meshes':[],'seams':[],'uv':[],'failures':[],'unverified':['Full-volume skin/fat shell thickness','Surface-to-surface interior intersection beyond the cut plane','Reduced LOD topology and seam identity','Published anthropometric ratios','Full-body garment and role silhouette acceptance']}
n=m['cut']['normal'];axis=Vector((n[0],-n[2],n[1]));u=Vector((1,0,0));v=axis.cross(u).normalized()
def xy(p):
 p=Vector(p);return Vector((p.dot(u),p.dot(v)))
def cross(a,b):return a.x*b.y-a.y*b.x
def segment_distance(p,a,b):
 delta=b-a;t=max(0,min(1,(p-a).dot(delta)/max(delta.length_squared,1e-20)))
 return (p-a-delta*t).length

def crossings(points):
 count=0
 for i,a in enumerate(points):
  b=points[(i+1)%len(points)]
  for j in range(i+2,len(points)):
   if i==0 and j==len(points)-1:continue
   c=points[j];d=points[(j+1)%len(points)]
   if cross(b-a,c-a)*cross(b-a,d-a)<-1e-14 and cross(d-c,a-c)*cross(d-c,b-c)<-1e-14:count+=1
 return count

for obj in bpy.data.objects:
 if obj.type!='MESH':continue
 obj.data.calc_loop_triangles();bm=bmesh.new();bm.from_mesh(obj.data)
 row={'name':obj.name,'triangles':len(obj.data.loop_triangles),'vertices':len(obj.data.vertices),'non_manifold_edges':sum(not e.is_manifold for e in bm.edges),'bad_weight_vertices':sum(abs(sum(g.weight for g in vert.groups)-1)>1e-4 or len(vert.groups)>4 or any(g.group>=len(obj.vertex_groups) for g in vert.groups) for vert in obj.data.vertices),'skin_group_names':len(obj.vertex_groups),'materials':len(obj.data.materials)}
 bm.free();report['meshes'].append(row)
 if row['non_manifold_edges'] or row['bad_weight_vertices']:report['failures'].append(obj.name+': manifold/weight failure')
for variant in range(3):
 a,b=m['cut']['seams'][variant*2:variant*2+2]
 ma=bpy.data.objects[a['object']].data;mb=bpy.data.objects[b['object']].data
 shape_errors={}
 for key in ma.shape_keys.key_blocks:
  other=mb.shape_keys.key_blocks[key.name]
  shape_errors[key.name]=max((key.data[i].co-other.data[j].co).length for i,j in zip(a['boundary_indices'],b['boundary_indices']))
 # Closed-fracture/rest seam matching is measured before any preview offset.
 outer=[xy(p) for p in a['boundary_positions']]
 skin=[xy(p) for p in a['layers']['1']['inner_ring_positions']]
 fat=[xy(p) for p in a['layers']['2']['inner_ring_positions']]
 values={}
 for name,inner,external,target in [('skin',skin,outer,2),('fat',fat,skin,4)]:
  samples=[min(segment_distance(point,external[i],external[(i+1)%len(external)]) for i in range(len(external)))*1000 for point in inner]
  values[name]={'min_mm':min(samples),'max_mm':max(samples),'target_mm':target,'self_intersections':crossings(inner),'method':'Minimum cut-plane distance from each inner vertex to the previous closed layer polyline'}
  if min(samples)<target-.15 or max(samples)>target+.15 or values[name]['self_intersections']:
   report['failures'].append(f'Variant {variant} {name}: normal-thickness/intersection tolerance failed')
 row={'variant':variant,'boundary_vertices':len(a['boundary_indices']),'max_shape_seam_error_m':shape_errors,'layer_thickness':values,'outer_self_intersections':crossings(outer)}
 report['seams'].append(row)
 if max(shape_errors.values())>1e-5:report['failures'].append(f'Variant {variant}: posed corrective boundary mismatch')

# Detect strictly positive UV overlap, excluding adjacent triangle pairs. Exact
# clipping follows a grid broad phase; touching island edges have zero area.
def polygon_area(points):return abs(sum(cross(points[i],points[(i+1)%len(points)]) for i in range(len(points))))*.5 if len(points)>=3 else 0

def intersection_area(first,second):
 poly=list(first)
 if cross(second[1]-second[0],second[2]-second[0])<0:second=list(reversed(second))
 for i,a in enumerate(second):
  b=second[(i+1)%3];edge=b-a;new=[]
  for j,start in enumerate(poly):
   end=poly[(j+1)%len(poly)];ds=cross(edge,start-a);de=cross(edge,end-a)
   if ds>=-1e-12:new.append(start)
   if (ds>0) != (de>0) and abs(ds-de)>1e-15:new.append(start+(end-start)*(ds/(ds-de)))
  poly=new
  if len(poly)<3:return 0
 return polygon_area(poly)
for name in ['HN_intact','HN_head_v0','HN_stump_v0']:
 obj=bpy.data.objects[name];mesh=obj.data;uv=mesh.uv_layers[0].data
 triangles=[];area=0;uv_area=0;zero=0
 for triangle in mesh.loop_triangles:
  if mesh.polygons[triangle.polygon_index].material_index!=0:continue
  points=[uv[i].uv.copy() for i in triangle.loops];a=polygon_area(points);area+=triangle.area;uv_area+=a
  if a<1e-12:zero+=1;continue
  triangles.append((points,set(triangle.vertices)))
 grid={};pairs=set();overlap=0;examples=[]
 for index,(points,verts) in enumerate(triangles):
  xs=[p.x for p in points];ys=[p.y for p in points]
  for x in range(math.floor(min(xs)*64),math.floor(max(xs)*64)+1):
   for y in range(math.floor(min(ys)*64),math.floor(max(ys)*64)+1):
    cell=grid.setdefault((x,y),[])
    for other in cell:
     pair=(other,index)
     if pair in pairs:continue
     pairs.add(pair)
     if len(verts & triangles[other][1])>=2:continue
     if intersection_area(points,triangles[other][0])>1e-10:
      overlap+=1
      if len(examples)<10:examples.append([other,index])
    cell.append(index)
 row={'mesh':name,'channel':'UV0, textured exterior material only','positive_overlap_triangle_pairs':overlap,'examples':examples,'zero_area_uv_triangles':zero,'aggregate_texels_per_meter_at_2048':2048*math.sqrt(uv_area/max(area,1e-12)),'density_is_local_stretch_approval':False}
 report['uv'].append(row)
 if overlap or zero:report['failures'].append(name+': exterior UV overlaps or zero-area triangles')
report['uv_note']='Tissue and interior materials use vertex colors; their UV0/UV2 overlap is not certified as a unique baked atlas.'
report['lods']=[{'lod':0,'available':True,'optimized':False},{'lod':1,'available':False},{'lod':2,'available':False},{'lod':3,'available':False}]
report['machine_passed']=not report['failures'] and not report['unverified']
(root/'geometry_validation.json').write_text(json.dumps(report,indent=2)+'\n')
print('REGION_VALIDATION',json.dumps({'failures':report['failures'],'unverified':report['unverified']}),flush=True)
