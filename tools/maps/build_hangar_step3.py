"""Blender 5: preserve supplied buildings; reconcile derivative meshes, add timber platforms.
Usage: script SOURCE_GLTF WAREHOUSE_GLB PREPARED_NPZ LAYOUT_JSON OUTPUT_GLB REPORT_JSON
"""
import bpy,bmesh,numpy as np,json,sys,math
from pathlib import Path
from mathutils import Matrix,Vector
source,warehouse,arrays,layout_path,dest,report_path=sys.argv[1:]
bpy.context.preferences.filepaths.use_scripts_auto_execute=False
bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=source)
data=np.load(arrays);layout=json.loads(Path(layout_path).read_text());log=[]
def clip_object(obj,openings):
 bm=bmesh.new();bm.from_mesh(obj.data)
 # Coordinates are Blender Z-up; cut below warehouse floor.
 bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),plane_co=(0,0,0),plane_no=(0,0,1),clear_inner=True,dist=1e-7)
 floor=[f for f in bm.faces if all(abs(v.co.z)<.002 for v in f.verts)]
 bmesh.ops.delete(bm,geom=floor,context='FACES')
 cut_count=0
 for lo,hi in openings:
  if not bm.verts:continue
  coords=np.array([v.co[:] for v in bm.verts])
  if np.any(coords.max(0)<lo) or np.any(coords.min(0)>hi):continue
  for axis in range(3):
   for value in [lo[axis],hi[axis]]:
    normal=[0,0,0];normal[axis]=1;point=[0,0,0];point[axis]=value
    bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),plane_co=point,plane_no=normal,dist=1e-7)
  inside=[f for f in bm.faces if all(lo[i]-1e-6<=f.calc_center_median()[i]<=hi[i]+1e-6 for i in range(3))]
  cut_count+=len(inside);bmesh.ops.delete(bm,geom=inside,context='FACES')
 bmesh.ops.delete(bm,geom=[v for v in bm.verts if not v.link_faces],context='VERTS')
 bmesh.ops.triangulate(bm,faces=list(bm.faces))
 bmesh.ops.delete(bm,geom=[f for f in bm.faces if f.calc_area()<1e-10 or all(abs(v.co.z)<.002 for v in f.verts)],context='FACES')
 bm.to_mesh(obj.data);bm.free();obj.data.update()
 return len(floor),cut_count
openings=[]
for entry in layout['egress']:
 x,y,z=entry['position'];w=entry['width']/2;d=entry['depth']/2
 openings.append((np.array([x-w,-z-d,-.01]),np.array([x+w,-z+d,entry['height']])))
for obj in [o for o in bpy.context.scene.objects if o.type=='MESH']:
 name=obj.name;coords=data[name+'_v'];assert len(coords)==len(obj.data.vertices)
 obj.parent=None;obj.matrix_world=Matrix.Identity(4)
 for vert,p in zip(obj.data.vertices,coords):vert.co=(float(p[0]),float(-p[2]),float(p[1]))
 if name=='Object_16':
  # Verify polygon indexing before using audited source face IDs.
  assert all(list(poly.vertices)==list(data[name+'_f'][i]) for i,poly in enumerate(obj.data.polygons))
  bm=bmesh.new();bm.from_mesh(obj.data);bm.faces.ensure_lookup_table()
  bmesh.ops.delete(bm,geom=[bm.faces[int(i)] for i in data[name+'_remove_faces']],context='FACES');bm.to_mesh(obj.data);bm.free()
 floor,cuts=clip_object(obj,openings);log.append({'object':name,'removed_floor_faces':floor,'egress_removed_fragments':cuts,'triangles_after':len(obj.data.polygons)})
 obj.name='Killhouse_'+name
 for mat in obj.data.materials:
  if mat and mat.use_nodes:
   bsdf=mat.node_tree.nodes.get('Principled BSDF')
   if bsdf:bsdf.inputs['Base Color'].default_value=(.42,.43,.44,1);bsdf.inputs['Roughness'].default_value=.8
# Preserve warehouse textures/UVs, remove only original closed door panel.
bpy.ops.import_scene.gltf(filepath=warehouse)
for obj in [o for o in bpy.context.scene.objects if o.type=='MESH' and not o.name.startswith('Killhouse_')]:
 matrix=obj.matrix_world.copy();obj.parent=None;obj.matrix_world=Matrix.Identity(4)
 for v in obj.data.vertices:v.co=matrix@v.co
 removed=0
 if 'Metal' in obj.name:
  bm=bmesh.new();bm.from_mesh(obj.data)
  panel=[f for f in bm.faces if all(3.95<=v.co.x<=12.05 and .073<=v.co.y<=.078 and -.03<=v.co.z<=2.98 for v in f.verts)]
  removed=len(panel);assert removed>0,'Door selector must match measured panel'
  bmesh.ops.delete(bm,geom=panel,context='FACES');bm.to_mesh(obj.data);bm.free()
 for mat in obj.data.materials:
  if mat:mat.use_backface_culling=False
 log.append({'object':obj.name,'door_panel_faces_removed':removed})
# New additions only: timber decking, supports, stair treads, rails and cover.
# These do not replace either imported building. Materials await Step 4.
wood=bpy.data.materials.new('Timber_Step3_Untextured');wood.diffuse_color=(.22,.12,.055,1);wood.use_nodes=True
wood.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=(.22,.12,.055,1);wood.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value=.78
added=[]
def timber(name,center,size):
 bpy.ops.mesh.primitive_cube_add(size=1,location=(center[0],-center[2],center[1]));obj=bpy.context.object;obj.name=name;obj.scale=(size[0],size[2],size[1]);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);obj.data.materials.append(wood)
 bevel=obj.modifiers.new('EdgeChamfer','BEVEL');bevel.width=.006;bevel.segments=1;bpy.context.view_layer.objects.active=obj;bpy.ops.object.modifier_apply(modifier=bevel.name);added.append(obj);return obj
for p in layout['platforms']:
 prefix=p['id'].title();x0,x1=p['x_bounds'];z0,z1=p['z_bounds'];deck=p['deck_y_m'];landing=p['stairs_top'][2];base=p['stairs_base'][2];far=z1 if p['id']=='north' else z0
 n=math.ceil((z1-z0)/.22);dz=(z1-z0)/n
 for i in range(n):timber(prefix+'_DeckPlank',[(x0+x1)/2,deck-.08,z0+(i+.5)*dz],[x1-x0,.16,dz-.004])
 for x in [x0+.10,x1-.10]:
  for z in np.linspace(z0+.12,z1-.12,4):timber(prefix+'_Post',[x,(deck-.16)/2,float(z)],[.18,deck-.16,.18])
  timber(prefix+'_LongBeam',[x,deck-.27,(z0+z1)/2],[.18,.22,z1-z0])
 # Stair treads: 12 equal rises, 32-degree overall envelope. Final colliders Step 6.
 rise=deck/12;run=abs(landing-base)/12
 for i in range(12):
  z=base+(landing-base)*(i+.5)/12
  timber(prefix+'_StairTread',[3.75,(i+1)*rise-.035,z],[1.2,.07,run+.025])
 # Structural stringers and stair handrails follow the actual 32-degree rise.
 for x in [3.09,4.41]:
  for offset,width,height,label in [(-.13,.14,.20,'Stringer'),(.95,.08,.08,'StairHandrail')]:
   a=Vector((x,-base,.03+offset));b=Vector((x,-landing,deck+offset));d=b-a;mid=(a+b)/2
   obj=timber(prefix+'_'+label,[mid.x,mid.z,-mid.y],[width,height,d.length]);obj.rotation_euler=d.to_track_quat('Y','Z').to_euler()
  for j in range(4):
   f=j/3;h=.03+(deck-.03)*f;z=base+(landing-base)*f
   timber(prefix+'_StairRailPost',[x,h+.5,z],[.08,1.0,.08])
 # Side guard rails with vertical posts. Open stairs on the short landing edge.
 for x in [x0+.05,x1-.05]:
  for z in np.linspace(z0+.07,z1-.07,5):timber(prefix+'_RailPost',[x,deck+.55,float(z)],[.10,1.1,.10])
  for h in [.45,1.05]:timber(prefix+'_Rail',[x,deck+h,(z0+z1)/2],[.10,.10,z1-z0])
 # Two 1.0 x .8 m slits on the far end wall, away from the stairs.
 for h,th in [(.1,.2),(1.05,.1)]:timber(prefix+'_SlitHorizontal',[(x0+x1)/2,deck+h,far],[x1-x0,th,.10])
 for lo,hi in [(x0,2.5),(3.5,4.25),(5.25,x1)]:timber(prefix+'_SlitPier',[(lo+hi)/2,deck+.6,far],[hi-lo,.8,.10])
 if p['id']=='north':
  timber(prefix+'_DeckCover',[3.5,deck+.6,-5.25],[.1,1.2,2.5]);timber(prefix+'_DeckCoverReturn',[4,deck+.6,-6.5],[1.1,1.2,.1])
 else:timber(prefix+'_DeckCover',[3.225,deck+.6,-41.5],[1.95,1.2,.1])
# Join only the new timber objects, retaining both imported buildings separately.
bpy.ops.object.select_all(action='DESELECT')
for obj in added:obj.select_set(True)
bpy.context.view_layer.objects.active=added[0];bpy.ops.object.join();bpy.context.object.name='Staging_TimberPlatforms'
# Egress marker frames are added without new enclosing walls.
for p in layout['egress']:
 x,y,z=p['position'];w=p['width'];h=p['height']
 timber(p['id']+'_EgressLeft',[x-w/2-.06,h/2,z],[.12,h,.15]);timber(p['id']+'_EgressRight',[x+w/2+.06,h/2,z],[.12,h,.15]);timber(p['id']+'_EgressLintel',[x,h+.06,z],[w+.24,.12,.15])
meshes=[o for o in bpy.context.scene.objects if o.type=='MESH'];tot=0
for obj in meshes:
 if wood not in obj.data.materials.values():continue
 bm=bmesh.new();bm.from_mesh(obj.data);bm.transform(obj.matrix_world)
 if min(v.co.z for v in bm.verts)<0:
  bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),plane_co=(0,0,0),plane_no=(0,0,1),clear_inner=True,dist=1e-7)
 bm.transform(obj.matrix_world.inverted());bm.to_mesh(obj.data);bm.free()

for obj in meshes:obj.data.calc_loop_triangles();tot+=len(obj.data.loop_triangles)
bpy.ops.object.select_all(action='DESELECT')
for obj in meshes:obj.select_set(True)
bpy.ops.export_scene.gltf(filepath=dest,export_format='GLB',use_selection=True,export_yup=True,export_copyright='Killhouse by _.quve and Warehouse FBX Model Free by Nicholas-3D, CC-BY-4.0. ZERO-LINE derivative; see CREDITS.md for sources and changes.')
Path(report_path).write_text(json.dumps({'blender':bpy.app.version_string,'triangles':tot,'mesh_objects':len(meshes),'edits':log,'platforms_built':2,'egress_frames_built':2,'stage':'3; materials, optimization, collision and navigation pending'},indent=2)+'\n')
print('STEP3_EXPORT',tot,flush=True)
