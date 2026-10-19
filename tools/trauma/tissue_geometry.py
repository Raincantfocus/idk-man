"""Shared closed CDT tissue-patch authoring helpers. Blender 4.3.2."""
import bpy,bmesh,math
from mathutils import Vector
from mathutils.geometry import delaunay_2d_cdt
def configure(**values):
 globals().update(values)

class Builder:
 def __init__(self):self.v=[];self.f=[];self.t=[];self.parts=[]
 def add(self,verts,faces,tissue,label):
  start=len(self.v);self.v.extend(verts);self.f.extend([tuple(i+start for i in f) for f in faces]);self.t.extend([tissue]*len(faces));self.parts.append({'name':label,'first_vertex':start,'vertex_count':len(verts),'tissue':tissue})
 def patch(self,points,z,depth,tissue,label,spacing=.009,rough=.001):
  n=len(points);sites=[Vector(p) for p in points]
  # Constrained Delaunay with staggered interior sites avoids center fans.
  xmin=min(p[0] for p in points);xmax=max(p[0] for p in points);ymin=min(p[1] for p in points);ymax=max(p[1] for p in points)
  def inside(x,y):
   flag=False
   for i,p in enumerate(points):
    q=points[(i+1)%n]
    if (p[1]>y)!=(q[1]>y) and x<(q[0]-p[0])*(y-p[1])/(q[1]-p[1])+p[0]:flag=not flag
   return flag
  row=0;y=ymin+spacing*.65
  while y<ymax:
   x=xmin+spacing*(.6+.4*(row%2))
   while x<xmax:
    if inside(x,y):sites.append(Vector((x,y)))
    x+=spacing
   row+=1;y+=spacing*.866
  vs,es,fs,orig,_,_=delaunay_2d_cdt(sites,[],[list(range(n))],1,1e-7)
  faces=[tuple(f) for f in fs if len(f)==3]
  assert faces,'Empty constrained patch'
  heights=[z+rough*(math.sin(p.x*913+seed)*.55+math.sin(p.y*1241-seed)*.45) for p in vs]
  verts=[(p.x,p.y,h) for p,h in zip(vs,heights)]+[(p.x,p.y,z-depth) for p in vs]
  m=len(vs);ff=faces+[tuple(i+m for i in reversed(f)) for f in faces]
  edges={}
  for f in faces:
   for a,b in zip(f,f[1:]+f[:1]):edges[tuple(sorted((a,b)))]=edges.get(tuple(sorted((a,b))),0)+1
  for (a,b),count in edges.items():
   if count==1:ff.append((a,b,b+m,a+m))
  self.add(verts,ff,tissue,label)
 def ellipse(self,cx,cy,sx,sy,z,tissue,label,n=14,angle=0,spacing=.008,rough=.001,depth=.009):
  pts=[]
  for i in range(n):
   a=2*math.pi*i/n;r=1+rough*60*math.sin(3*a+seed)
   x=sx*math.cos(a)*r;y=sy*math.sin(a)*r
   pts.append((cx+x*math.cos(angle)-y*math.sin(angle),cy+x*math.sin(angle)+y*math.cos(angle)))
  self.patch(pts,z,depth,tissue,label,spacing,rough)
 def tube(self,cx,cy,sx,sy,z,wall,tissue,label,n=16):
  assert sx>wall and sy>wall
  verts=[]
  # Four loops form a sealed thick-walled open-ended tube, no end fan.
  for radius,h in [(1,-.009),(1,z),(0,z), (0,-.009)]:
   for i in range(n):
    a=2*math.pi*i/n;ex=sx if radius else sx-wall;ey=sy if radius else max(sy-wall,.0006)
    verts.append((cx+ex*math.cos(a),cy+ey*math.sin(a),h+.0007*math.sin(3*a+seed)))
  faces=[]
  for row in range(4):
   for i in range(n):j=(i+1)%n;faces.append((row*n+i,row*n+j,((row+1)%4)*n+j,((row+1)%4)*n+i))
  self.add(verts,faces,tissue,label)
  # Recessed dark blood floor is a separate non-fan closed patch.
  self.ellipse(cx,cy,(sx-wall)*.96,max(sy-wall,.0006)*.96,-.008,6,label+'_lumen',n=max(8,n//2),spacing=.004,rough=.0001,depth=.001)
 def border(self):
  n=len(outline);verts=[]
  for row in range(4):
   for i,p in enumerate(outline):
    inset=.0018+(.0006*math.sin(i*1.9+seed))
    factor=1-(inset/max(p.length,.001) if row in [1,2] else (.0008/max(p.length,.001) if row==3 else 0))
    # Outer row matches the original source border exactly; inner lip retracts.
    h=seam_z[i] if row==0 else (-.003-.002*math.sin(i*.7+seed)**2 if row==1 else -.008)
    verts.append((p.x*factor,p.y*factor,h))
  faces=[]
  for row in range(4):
   for i in range(n):j=(i+1)%n;faces.append((row*n+i,row*n+j,((row+1)%4)*n+j,((row+1)%4)*n+i))
  self.add(verts,faces,0,'retracted_skin')
  # Fat is broken into small lobulated pads, never a continuous yellow outline.
  for i in [int(len(outline)*f) for f in [.08,.28,.50,.73,.95]]:
   p=outline[i]*.91;self.ellipse(p.x,p.y,.006,.003,-.003,1,'fat_lobule',n=8,spacing=.007,rough=.0005,depth=.004)
  for i in [int(len(outline)*f) for f in [.12,.45,.81]]:
   p=outline[i]*.98;t=Vector((-p.y,p.x)).normalized();q=p.normalized()
   pts=[p-t*.006,p+t*.006,p+t*.004+q*.006,p-t*.003+q*.004]
   self.patch(pts,.003+tear*.002,.003,0,'skin_flap',spacing=.004,rough=.0012)
 def mesh(self,name):
  mesh=bpy.data.meshes.new(name);mesh.from_pydata(self.v,[],self.f);mesh.update()
  obj=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(obj);mesh.materials.append(mat)
  mesh.uv_layers.new(name='TissueAtlas');mesh.color_attributes.new(name='CavityFlow',type='FLOAT_COLOR',domain='CORNER')
  uv=mesh.uv_layers['TissueAtlas'];col=mesh.color_attributes['CavityFlow']
  for poly,tissue in zip(mesh.polygons,self.t):
   for li in poly.loop_indices:
    p=mesh.vertices[mesh.loops[li].vertex_index].co
    # Padded tile mapping; local dimensional coordinates preserve fiber orientation.
    x=(p.x/(rx*2.6)+.5)*.9+.05;y=(p.y/(ry*2.6)+.5)*.9+.05
    if abs(poly.normal.z)<.45:
     x=(.5+(p.x*poly.normal.y-p.y*poly.normal.x)/max(.25,max(rx,ry)*2.6))*.9+.05
     y=(.5+p.z/.08)*.9+.05
    uv.data[li].uv=((tissue%4+x)/4,(tissue//4+y)/4)
    cavity=max(0,min(1,(-p.z+.005)/.025));nearest=min(range(len(outline)),key=lambda j:(outline[j]-Vector((p.x,p.y))).length_squared)
    col.data[li].color=(cavity,.5+p.y/(ry*2.6),float(tissue)/15,.5+seam_z[nearest]/.02)
   poly.use_smooth=True
  bm=bmesh.new();bm.from_mesh(mesh);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(mesh);bm.free();mesh.calc_loop_triangles()
  return obj

def stats(obj):
 bm=bmesh.new();bm.from_mesh(obj.data);obj.data.calc_loop_triangles()
 d={'name':obj.name,'triangles':len(obj.data.loop_triangles),'non_manifold_edges':sum(not e.is_manifold for e in bm.edges),'vertices':len(bm.verts),'materials':len(obj.data.materials),'max_vertex_edge_valence':max(len(x.link_edges) for x in bm.verts),'relief_m':max(p.co.z for p in obj.data.vertices)-min(p.co.z for p in obj.data.vertices)};bm.free();return d

def export(obj,path):
 bpy.ops.object.select_all(action='DESELECT');obj.hide_set(False);obj.select_set(True);bpy.context.view_layer.objects.active=obj
 bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_animations=False,export_yup=True,export_all_vertex_colors=True,export_tangents=True,export_materials='NONE')
