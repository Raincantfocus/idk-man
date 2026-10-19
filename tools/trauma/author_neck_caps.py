"""Blender 4.3+; run with existing head_neck_authoring.blend loaded.
blender -b SOURCE.blend -P tools/trauma/author_neck_caps.py -- PRIVATE_OUTPUT
Geometry and purchased exterior exports stay outside the repository.
"""
import bpy,bmesh,json,math,sys,random,hashlib
import numpy as np
from pathlib import Path
from mathutils import Vector
from mathutils.geometry import delaunay_2d_cdt
ROOT=Path(__file__).resolve().parents[2]
CFG=json.loads((ROOT/'data/trauma/neck_rework.json').read_text())
out=Path(sys.argv[sys.argv.index('--')+1]).resolve();out.mkdir(parents=True,exist_ok=True)
assert not out.is_relative_to(ROOT),'Do not write derived source art into the checkout'
source_manifest=json.loads((Path(bpy.data.filepath).parent.parent/'manifest.json').read_text())
# Work in cap-local XY, +Z outward. V points anterior in the fitted Blender source.
def from_godot(x):return Vector((x[0],-x[2],x[1]))
axis=from_godot(source_manifest['cut']['normal']);u=Vector((1,0,0));v=axis.cross(u).normalized()
seam=source_manifest['cut']['seams'][0]['boundary_positions']
center=sum((Vector(p) for p in seam),Vector())/len(seam)
outline=[Vector(((Vector(p)-center).dot(u),(Vector(p)-center).dot(v))) for p in seam]
seam_z=[(Vector(p)-center).dot(axis) for p in seam]
# Source anatomical front is Blender -Y: local negative V is anterior.
rx=max(abs(p.x) for p in outline);ry=max(abs(p.y) for p in outline)
print('CAP_DIMENSIONS',rx,ry,flush=True)
for obj in bpy.context.scene.objects:obj.hide_render=True

# Shared original atlas: no source photographs or baked light. Eight tissue tiles.
N=CFG['atlas_size'];yy,xx=np.mgrid[0:N,0:N];U=(xx%(N//4))/(N//4);V=(yy%(N//4))/(N//4)
tile=np.minimum(xx//(N//4)+4*(yy//(N//4)),7).astype(int)
rng=np.random.default_rng(CFG['seed']);noise=rng.random((N,N),dtype=np.float32)-.5
fiber=np.sin(U*210+np.sin(V*18)*1.6)*.5+.5
lobule=np.sin(U*39+np.sin(V*18))*np.sin(V*43+np.cos(U*17))
palette=np.array([[.40,.23,.20],[.57,.47,.34],[.18,.085,.072],[.57,.49,.42],[.64,.57,.44],[.52,.50,.42],[.012,.006,.008],[.10,.012,.018]],dtype=np.float32)
color=palette[tile]*(1+noise[...,None]*.12+(fiber[...,None]-.5)*np.where(tile==2,.09,.04)[...,None]+lobule[...,None]*np.where(tile==1,.09,.025)[...,None])
height=noise*.035+fiber*np.where(tile==2,.13,.025)+lobule*np.where(tile==1,.08,.015)
gy,gx=np.gradient(height);normal=np.stack((-gx*2,-gy*2,np.ones_like(gx)),axis=-1);normal/=np.linalg.norm(normal,axis=-1)[...,None]
rough=np.choose(tile,[.53,.39,.28,.23,.57,.22,.15,.18])
flow=np.stack((np.clip(.5+lobule*.22,0,1),V,np.clip(fiber,0,1)),axis=-1)
def save_image(name,data):
 im=bpy.data.images.new(name,width=N,height=N,alpha=True)
 rgba=np.concatenate((data.astype(np.float32),np.ones((N,N,1),np.float32)),axis=-1)
 im.pixels.foreach_set(rgba.ravel());im.filepath_raw=str(out/(name+'.png'));im.file_format='PNG';im.save();return im
albedo=save_image('tissue_albedo',np.clip(color,0,1));norm=save_image('tissue_normal',normal*.5+.5)
orm=save_image('tissue_orm',np.stack((np.ones_like(rough),rough,np.zeros_like(rough)),axis=-1));flowim=save_image('tissue_flow',flow)
mat=bpy.data.materials.new('Shared_Neck_Tissue_2K');mat.use_nodes=True
nodes=mat.node_tree.nodes;links=mat.node_tree.links;bs=nodes.get('Principled BSDF');bs.inputs['Metallic'].default_value=0
for im,target in [(albedo,'Base Color')]:
 tex=nodes.new('ShaderNodeTexImage');tex.image=im;links.new(tex.outputs['Color'],bs.inputs[target])
tex=nodes.new('ShaderNodeTexImage');tex.image=norm;norm.colorspace_settings.name='Non-Color';nm=nodes.new('ShaderNodeNormalMap');nm.inputs['Strength'].default_value=.4;links.new(tex.outputs['Color'],nm.inputs['Color']);links.new(nm.outputs['Normal'],bs.inputs['Normal'])
bs.inputs['Roughness'].default_value=.33

report={'engine':'4.6.3','production_approved':False,'source':'Soup supplied fitted head','cap_local_axes':'+X right, -Y anterior, +Z outward','meshes':[], 'boundary_count':len(outline),'cap_unique_lod0':12,'atlas_dimension':N,'scope':'Head/neck only','unverified':['Full posed skin-under-cloth continuity','General 3D inter-tissue intersection','Hardware GPU frame-time','Detailed skull cortex/marrow fragment layers and live corpse integration']}
manifest={'schema':2,'region':'head_neck','variants':[],'source_center_blender':list(center),'source_basis_blender':[list(u),list(v),list(axis)],'source_boundary':seam,'sockets':[],'atlas':['tissue_albedo.png','tissue_normal.png','tissue_orm.png','tissue_flow.png']}
allcaps=[]
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
  for i in [5,18,32,47,62]:
   p=outline[i]*.91;self.ellipse(p.x,p.y,.006,.003,-.003,1,'fat_lobule',n=8,spacing=.007,rough=.0005,depth=.004)
  for i in [8,29,52]:
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
    x=(p.x/(rx*2)+.5)*.9+.05;y=(p.y/(ry*2)+.5)*.9+.05
    if abs(poly.normal.z)<.45:
     x=(.5+(p.x*poly.normal.y-p.y*poly.normal.x)/.25)*.9+.05
     y=(.5+p.z/.08)*.9+.05
    uv.data[li].uv=((tissue%4+x)/4,(tissue//4+y)/4)
    cavity=max(0,min(1,(-p.z+.005)/.025));nearest=min(range(len(outline)),key=lambda j:(outline[j]-Vector((p.x,p.y))).length_squared)
    col.data[li].color=(cavity,.5+p.y/(ry*2),float(tissue)/15,.5+seam_z[nearest]/.02)
   poly.use_smooth=True
  bm=bmesh.new();bm.from_mesh(mesh);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(mesh);bm.free();mesh.calc_loop_triangles()
  return obj

def stats(obj):
 bm=bmesh.new();bm.from_mesh(obj.data);obj.data.calc_loop_triangles()
 d={'name':obj.name,'triangles':len(obj.data.loop_triangles),'non_manifold_edges':sum(not e.is_manifold for e in bm.edges),'vertices':len(bm.verts),'materials':len(obj.data.materials),'max_vertex_edge_valence':max(len(x.link_edges) for x in bm.verts),'relief_m':max(p.co.z for p in obj.data.vertices)-min(p.co.z for p in obj.data.vertices)};bm.free();return d

def export(obj,path):
 bpy.ops.object.select_all(action='DESELECT');obj.hide_set(False);obj.select_set(True);bpy.context.view_layer.objects.active=obj
 bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_animations=False,export_yup=True,export_all_vertex_colors=True,export_tangents=True,export_materials='NONE')

def cdt_close_face(bm,face,material_index,spacing=.012):
 # Project onto the cut face and insert staggered interior sites before CDT.
 # Existing border vertices are retained exactly, even on a slightly nonplanar loop.
 ring=list(face.verts);origin=sum((x.co for x in ring),Vector())/len(ring)
 normal=face.normal.normalized();horizontal=normal.orthogonal().normalized();vertical=normal.cross(horizontal)
 points=[Vector(((p.co-origin).dot(horizontal),(p.co-origin).dot(vertical))) for p in ring]
 lo=Vector((min(p.x for p in points),min(p.y for p in points)));hi=Vector((max(p.x for p in points),max(p.y for p in points)))
 sites=points.copy();y=lo.y+spacing*.5;row=0
 while y<hi.y:
  x=lo.x+spacing*(.5+.4*(row%2))
  while x<hi.x:
   inside=False
   for i,p in enumerate(points):
    q=points[(i+1)%len(points)]
    if (p.y>y)!=(q.y>y) and x<(q.x-p.x)*(y-p.y)/(q.y-p.y)+p.x:inside=not inside
   if inside:sites.append(Vector((x,y)))
   x+=spacing
  row+=1;y+=spacing*.866
 vs,_,faces,orig,_,_=delaunay_2d_cdt(sites,[],[list(range(len(ring)))],1,1e-7)
 converted=[]
 for xy,ids in zip(vs,orig):
  old=next((i for i in ids if i<len(ring)),None)
  relief=.004*math.sin(xy.x*311+seed)*math.sin(xy.y*273-seed) if material_index==2 else 0.0
  converted.append(ring[old] if old is not None else bm.verts.new(origin+horizontal*xy.x+vertical*xy.y+normal*relief))
 bm.faces.remove(face)
 for indices in faces:
  f=bm.faces.new([converted[i] for i in indices]);f.material_index=material_index
  xy=sum((vs[i] for i in indices),Vector((0,0)))/len(indices)
  distances=[]
  for j,a in enumerate(points):
   delta=points[(j+1)%len(points)]-a
   t=max(0,min(1,(xy-a).dot(delta)/max(delta.length_squared,1e-12)))
   distances.append((xy-a-delta*t).length)
  tissue=2
  for loop in f.loops:
   p=loop.vert.co
   for uv in bm.loops.layers.uv.values():loop[uv].uv=((tissue%4+.05+.9*(p.x/(2*rx)+.5))/4,(tissue//4+.05+.9*(p.y/(2*ry)+.5))/4)
   point=Vector(((p-origin).dot(horizontal),(p-origin).dot(vertical)));edge_distance=1.0
   for j,a in enumerate(points):
    delta=points[(j+1)%len(points)]-a;t=max(0,min(1,(point-a).dot(delta)/max(delta.length_squared,1e-12)));edge_distance=min(edge_distance,(point-a-delta*t).length)
   edge=max(0,1-edge_distance/.005)
   for color in bm.loops.layers.float_color.values():loop[color]=(.3,edge,0,.5)
 return len(faces)

def bake_cap_tile(obj,tile_id):
 # Orthographic geometric bake: select highest triangle per texel. Albedo is
 # tissue pigment only, normals derive the actual height field; no baked light.
 size=N//4;iy,ix=np.mgrid[0:size,0:size]
 px=((ix+.5)/size-.05)/.9*(2*rx)-rx
 py=((iy+.5)/size-.05)/.9*(2*ry)-ry
 top=np.full((size,size),-1.,np.float32);colors=np.zeros((size,size,3),np.float32)
 obj.data.calc_loop_triangles()
 for tri in obj.data.loop_triangles:
  pts=np.array([obj.data.vertices[i].co[:] for i in tri.vertices]);a,bb,c=pts
  den=(bb[1]-c[1])*(a[0]-c[0])+(c[0]-bb[0])*(a[1]-c[1])
  if abs(den)<1e-10:continue
  x0=max(0,int(((pts[:,0].min()+rx)/(2*rx)*.9+.05)*size)-1);x1=min(size,int(((pts[:,0].max()+rx)/(2*rx)*.9+.05)*size)+2)
  y0=max(0,int(((pts[:,1].min()+ry)/(2*ry)*.9+.05)*size)-1);y1=min(size,int(((pts[:,1].max()+ry)/(2*ry)*.9+.05)*size)+2)
  X=px[y0:y1,x0:x1];Y=py[y0:y1,x0:x1]
  w0=((bb[1]-c[1])*(X-c[0])+(c[0]-bb[0])*(Y-c[1]))/den
  w1=((c[1]-a[1])*(X-c[0])+(a[0]-c[0])*(Y-c[1]))/den;w2=1-w0-w1
  z=w0*a[2]+w1*bb[2]+w2*c[2]
  hit=(w0>=0)&(w1>=0)&(w2>=0)&(z>top[y0:y1,x0:x1])
  uv=obj.data.uv_layers.active.data[tri.loops[0]].uv
  tissue=min(7,int(uv.x*4)+4*int(uv.y*4))
  top[y0:y1,x0:x1][hit]=z[hit];colors[y0:y1,x0:x1][hit]=palette[tissue]
 top[top<-.1]=-.013
 gy,gx=np.gradient(top,2*ry/size,2*rx/size);nm=np.stack((-gx,-gy,np.ones_like(gx)),axis=-1);nm/=np.linalg.norm(nm,axis=-1)[...,None]
 colors*=1+np.sin(px*2500)[...,None]*.03
 ox=(tile_id%4)*size;oy=(tile_id//4)*size
 for im,values in [(albedo,colors),(norm,nm*.5+.5),(orm,np.stack((np.ones_like(top),np.full_like(top,.35),np.zeros_like(top)),axis=-1))]:
  pixels=np.array(im.pixels[:],dtype=np.float32).reshape(N,N,4);pixels[oy:oy+size,ox:ox+size,:3]=values;im.pixels.foreach_set(pixels.ravel());im.save()

for weapon,params in CFG['weapons'].items():
 for variant in range(CFG['variants_per_weapon']):
  seed=CFG['seed']+list(CFG['weapons']).index(weapon)*31+variant*7;tear=params['tear'];relief=params['relief']
  b=Builder();b.patch(outline,-.010,.003,7,'recessed_connective_bed',spacing=.018,rough=.001);b.border()
  # Muscle islands follow compartment layout, not concentric rings.
  for x,y,sx,sy,ang,label in [(-.047,-.017,.017,.035,-.5,'SCM_L'),(.047,-.017,.017,.035,.5,'SCM_R'),(-.013,-.052,.010,.020,0,'strap_L'),(.013,-.052,.010,.020,0,'strap_R'),(-.037,.050,.022,.030,-.3,'trapezius_L'),(.037,.050,.022,.030,.3,'trapezius_R'),(-.020,.013,.010,.015,0,'deep_L'),(.020,.013,.010,.015,0,'deep_R')]:
   z=(.010+.004*math.sin(seed+x*500))*relief
   if weapon=='shotgun' and label.startswith('strap'):z*=.3;sx*=.65
   b.ellipse(x,y,sx,sy,z,2,label,n=12,angle=ang,spacing=.010,rough=.0025*tear,depth=z+.009)
  # Trachea, collapsed esophagus, paired arteries and wider thin-wall veins.
  b.tube(0,-.018,.010,.009,.020*relief,.0015,3,'trachea',n=18)
  b.tube(-.004,.001,.006,.0028,.012*relief,.0011,2,'esophagus',n=14)
  for side in [-1,1]:
   b.tube(side*.021,-.014,.0033,.0033,.023*relief,.0011,2,'carotid_'+str(side),n=12)
   b.tube(side*.029,-.010,.005,.0042,.015*relief,.00065,2,'jugular_'+str(side),n=12)
  # C-shaped cartilage bands: missing posterior arc, joined strip with real walls.
  for z in [.005,.010,.015]:
   verts=[];n=12
   for r,h in [(1,z),(1,z+.0015),(1.13,z+.0015),(1.13,z)]:
    for i in range(n):
     a=math.pi*.72+(math.pi*1.56)*i/(n-1);verts.append((.010*r*math.cos(a),-.018+.009*r*math.sin(a),h*relief))
   faces=[]
   for j in range(4):
    for i in range(n-1):faces.append((j*n+i,j*n+i+1,((j+1)%4)*n+i+1,((j+1)%4)*n+i))
   faces.extend([(0,n,2*n,3*n),(n-1,4*n-1,3*n-1,2*n-1)]);b.add(verts,faces,5,'C_cartilage')
  b.ellipse(0,.021,.012,.009,.010*relief,4,'vertebral_body',n=14,spacing=.006,rough=.0015*tear,depth=.020)
  b.tube(0,.037,.007,.006,.008*relief,.002,4,'spinal_canal',n=14)
  b.ellipse(0,.037,.0023,.0028,.003,3,'spinal_cord',n=8,spacing=.003,rough=.0003,depth=.009)
  b.patch([(-.004,.040),(.004,.040),(.003,.056),(-.002,.058)],.009*relief,.018,4,'spinous_process',spacing=.006,rough=.001*tear)
  b.ellipse(0,.058,.002,.006,.003,3,'nuchal_ligament',n=8,spacing=.004,rough=.0002,depth=.010)
  obj=b.mesh(f'neck_{weapon}_{variant}_LOD0');allcaps.append(obj)
  st=stats(obj);st['weapon']=weapon;st['variant']=variant;st['parts']=b.parts
  st['boundary_match_max_error_m']=max((Vector(b.v[b.parts[1]['first_vertex']+i])-Vector((p.x,p.y,seam_z[i]))).length for i,p in enumerate(outline))
  st['tube_wall_min_m']=.00065;st['tube_wall_max_m']=.002
  st['height_bands_m']={}
  for part in b.parts:
   zs=[b.v[i][2] for i in range(part['first_vertex'],part['first_vertex']+part['vertex_count'])]
   st['height_bands_m'][part['name']]=[min(zs),max(zs)]
  st['thickness_method']='Analytic tube radial wall dimensions; skin lip 1.2–2.4 mm radial inset. Full-volume surface clearance not certified.'
  report['meshes'].append(st);export(obj,out/(obj.name+'.glb'))
  lods=[obj.name+'.glb']
  # Actual reduction; preserve a record if lumen/outline fidelity requires cleanup.
  for lod,target in [(1,800),(2,320)]:
   reduced=obj.copy();reduced.data=obj.data.copy();bpy.context.collection.objects.link(reduced);reduced.name=f'neck_{weapon}_{variant}_LOD{lod}'
   if lod==1:
    mod=reduced.modifiers.new('MeasuredReduction','DECIMATE');mod.ratio=target/st['triangles'];bpy.context.view_layer.objects.active=reduced
    bpy.ops.object.modifier_apply(modifier=mod.name)
   else:
    baked=Builder();baked.patch(outline,-.002,.006,8+list(CFG['weapons']).index(weapon),'single_baked_cap',spacing=1,rough=.001)
    low=baked.mesh('temporary_baked');reduced.data=low.data;bpy.data.objects.remove(low,do_unlink=True)
   rstats=stats(reduced);rstats['lod']=lod;report['meshes'].append(rstats)
   export(reduced,out/(reduced.name+'.glb'));lods.append(reduced.name+'.glb');reduced.hide_render=True
  if variant==0:bake_cap_tile(obj,8+list(CFG['weapons']).index(weapon))
  manifest['variants'].append({'id':f'{weapon}_{variant}','weapon':weapon,'index':variant,'lods':lods,'triangles':st['triangles'],'parts':[p['name'] for p in b.parts]})
  obj.hide_render=True

# Export the supplied paired exterior with old fan geometry removed. Close each
# shell using constrained triangles at its original boundary; replacement cap
# covers the closure. No radial center vertex is introduced.
closure_mat=bpy.data.materials.new('Recessed_closed_shell');closure_mat.use_nodes=True
closure_bs=closure_mat.node_tree.nodes.get('Principled BSDF');closure_bs.inputs['Base Color'].default_value=(.025,.005,.008,1);closure_bs.inputs['Roughness'].default_value=.65
for label in ['head','stump']:
 obj=bpy.data.objects['HN_'+label+'_v0'].copy();obj.data=obj.data.copy();bpy.context.collection.objects.link(obj);obj.name='Supplied_'+label
 obj.shape_key_clear();obj.data.materials[1]=closure_mat;bm=bmesh.new();bm.from_mesh(obj.data);layer=bm.faces.layers.int.get('wound_layer_id')
 bad=[f for f in bm.faces if layer and f[layer]>0];bmesh.ops.delete(bm,geom=bad,context='FACES')
 loose=[p for p in bm.verts if not p.link_faces];bmesh.ops.delete(bm,geom=loose,context='VERTS')
 # The cap shell remains open at the exact matching source seam. Report this
 # explicitly rather than describing coincident separate objects as welded.
 bm.to_mesh(obj.data);bm.free();obj.data.update()
 for vert in obj.data.vertices:
  p=vert.co-center;vert.co=Vector((p.dot(u),p.dot(v),p.dot(axis)))
 # Review is rigid rest pose; preserve the original rig in the earlier archive.
 for mod in list(obj.modifiers):obj.modifiers.remove(mod)
 # Seal the exterior seam using constrained triangles without a center vertex.
 bm=bmesh.new();bm.from_mesh(obj.data)
 boundary_edges=[e for e in bm.edges if e.is_boundary]
 if boundary_edges:
  made=bmesh.ops.holes_fill(bm,edges=boundary_edges,sides=0)['faces']
  recessed=[]
  for face in made:
   ring=list(face.verts);bm.faces.remove(face)
   inner=[bm.verts.new(Vector((p.co.x*.99,p.co.y*.99,.018 if label=='head' else -.018))) for p in ring]
   for i,a in enumerate(ring):
    q=bm.faces.new((a,ring[(i+1)%len(ring)],inner[(i+1)%len(ring)],inner[i]));q.material_index=1
   f=bm.faces.new(inner);f.material_index=1;recessed.append(f)
  for face in recessed:cdt_close_face(bm,face,1)
  bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
 bm.to_mesh(obj.data);bm.free();obj.data.update()
 # Source texture references export embedded to keep standalone review portable.
 bpy.ops.object.select_all(action='DESELECT');obj.hide_set(False);obj.select_set(True);bpy.context.view_layer.objects.active=obj
 bpy.ops.export_scene.gltf(filepath=str(out/('supplied_'+label+'.glb')),export_format='GLB',use_selection=True,export_animations=False,export_yup=True,export_tangents=True,export_all_vertex_colors=True)
 obj.hide_render=True
 manifest[label+'_exterior']='supplied_'+label+'.glb'
 report[label+'_exterior']=stats(obj)
# Four source-derived head-pop pieces, including a lower jaw/face piece.
# They are rigid review fragments; source skin is retained and cut faces are
# triangulated polygons, not radial center fans. Skull microstructure is absent.
manifest['head_pop']=[]
head_source=bpy.data.objects['Supplied_head']
fragment_cuts=[('jaw',[(Vector((0,0,.085)),Vector((0,0,1)),False)]),('cranial_left',[(Vector((0,0,.085)),Vector((0,0,1)),True),(Vector(),Vector((1,0,0)),False)]),('cranial_front',[(Vector((0,0,.085)),Vector((0,0,1)),True),(Vector(),Vector((1,0,0)),True),(Vector(),Vector((0,1,0)),False)]),('cranial_back',[(Vector((0,0,.085)),Vector((0,0,1)),True),(Vector(),Vector((1,0,0)),True),(Vector(),Vector((0,1,0)),True)])]
for name,cuts in fragment_cuts:
 frag=head_source.copy();frag.data=head_source.data.copy();frag.name='head_pop_'+name;bpy.context.collection.objects.link(frag)
 frag.data.materials.append(mat);bm=bmesh.new();bm.from_mesh(frag.data)
 for co,no,positive in cuts:
  bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),plane_co=co,plane_no=no,dist=1e-6,clear_inner=positive,clear_outer=not positive)
  made=bmesh.ops.holes_fill(bm,edges=[e for e in bm.edges if e.is_boundary],sides=0)['faces']
  for f in made:
   f.material_index=2
   for loop in f.loops:
    p=loop.vert.co;loop[bm.loops.layers.uv[0]].uv=((.05+.9*(p.x/(2*rx)+.5))/4,(1+.05+.9*(p.y/(2*ry)+.5))/4)
  for f in made:cdt_close_face(bm,f,2)
 bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(frag.data);bm.free();frag.data.calc_loop_triangles()
 bpy.ops.object.select_all(action='DESELECT');frag.hide_set(False);frag.select_set(True);bpy.context.view_layer.objects.active=frag
 path=out/(frag.name+'.glb')
 bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_animations=False,export_yup=True,export_tangents=True,export_all_vertex_colors=True)
 st=stats(frag);report.setdefault('head_pop_fragments',[]).append(st);manifest['head_pop'].append({'id':name,'path':path.name,'triangles':st['triangles']});frag.hide_render=True

manifest['sockets']=[{'name':name,'position':[x,z,-y],'direction':[0,1,0]} for name,x,y,z in [('carotid_L',-.021,-.014,.023),('carotid_R',.021,-.014,.023),('jugular_L',-.029,-.010,.015),('jugular_R',.029,-.010,.015),('trachea',0,-.018,.020)]]
report['atlas_uncompressed_rgba8_mip_bytes']=N*N*4*4*4//3
report['source_exteriors_closed']=report['head_exterior']['non_manifold_edges']==0 and report['stump_exterior']['non_manifold_edges']==0
report['mesh_file_bytes']=sum(p.stat().st_size for p in out.glob('neck*.glb'))
report['checks']={'caps_closed':all(x['non_manifold_edges']==0 for x in report['meshes']),'lod0_budget':all(x['triangles']<=4000 for x in report['meshes'] if x['name'].endswith('LOD0')),'boundary_match':all(x.get('boundary_match_max_error_m',0)<1e-6 for x in report['meshes']),'minimum_relief':all(x['relief_m']>=.005 for x in report['meshes']),'no_high_valence_fan':all(x['max_vertex_edge_valence']<25 for x in report['meshes'])}
report['limitations']=['Exterior and cap shells are separately closed at matching border positions, not a single welded surface','LOD2 uses one shared baked tile per weapon family; variant-specific small tears intentionally collapse at distance','Source original face repair may still contain a center fan away from cut; replacement caps do not use center fans','LOD1/2 require visual lumen and skin-border preservation review','New caps use rigid region transforms; full posed skin/cloth continuity is not certified']
(out/'manifest.json').write_text(json.dumps(manifest,indent=2));(out/'validation.json').write_text(json.dumps(report,indent=2))
folder=out/'authoring';folder.mkdir(exist_ok=True);(folder/'.gdignore').touch();bpy.context.preferences.filepaths.save_version=0;bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(folder/'neck_rework.blend'),compress=True)
print('NECK_REWORK',json.dumps(report['checks']),flush=True)
