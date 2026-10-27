import numpy as np,json,struct
from pathlib import Path
root=Path('/workspace/map-intake')
def rays(tri,orig,direction):
 d=np.array(direction);e1=tri[:,1]-tri[:,0];e2=tri[:,2]-tri[:,0];h=np.cross(d,e2);a=np.sum(e1*h,1);valid=np.abs(a)>1e-10;f=np.zeros_like(a);f[valid]=1/a[valid];s=orig-tri[:,0];u=f*np.sum(s*h,1);q=np.cross(s,e1);v=f*np.sum(q*d,1);t=f*np.sum(q*e2,1);return t[valid&(u>=-1e-7)&(v>=-1e-7)&(u+v<=1.0000001)&(t>1e-6)]
w=np.load(root/'warehouse.npz');rows=json.load(open(root/'warehouse.json'));r=rows[0];tri=w[r['key']+'_v'][w[r['key']+'_f']]
roof=[]
for x in np.linspace(.1,15.9,33):
 t=rays(tri,np.array([x,8,-23.075]),[0,-1,0]);roof.append([float(x),float(8-t.min()) if len(t) else None])
(root/'roof_profile.json').write_text(json.dumps(roof,indent=2))
# Front-elevation high-area sheets expose the door's own triangulated panel boundaries.
front=[]
for i,t in enumerate(tri):
 if np.ptp(t[:,2])<.001 and abs(t[:,2].mean())<.15:
  area=np.linalg.norm(np.cross(t[1]-t[0],t[2]-t[0]))/2
  if area>.2:front.append({'triangle':i,'area':float(area),'vertices':t.tolist()})
(root/'front_faces.json').write_text(json.dumps(front,indent=2))
print('FRONT',front)
# Structural horizontal slice: extract axis-parallel segments and group close parallel faces.
k=np.load(root/'killhouse.npz');rows=json.load(open(root/'killhouse.json'));r=next(r for r in rows if r['name']=='Object_16');tri=k[r['key']+'_v'][k[r['key']+'_f']]
y=.05;segments=[]
for t in tri:
 points=[]
 for a,b in [(0,1),(1,2),(2,0)]:
  if (t[a,1]-y)*(t[b,1]-y)<0:points.append(t[a]+(t[b]-t[a])*(y-t[a,1])/(t[b,1]-t[a,1]))
 if len(points)==2:
  a,b=points
  if abs(a[0]-b[0])<1e-5:segments.append([0,(a[0]+b[0])/2,min(a[2],b[2]),max(a[2],b[2])])
  elif abs(a[2]-b[2])<1e-5:segments.append([2,(a[2]+b[2])/2,min(a[0],b[0]),max(a[0],b[0])])
gaps=[]
for axis in [0,2]:
 groups=[]
 for s in sorted([s for s in segments if s[0]==axis],key=lambda s:s[1]):
  if not groups or s[1]-groups[-1][0][1]>.08:groups.append([])
  groups[-1].append(s)
 for group in groups:
  intervals=[]
  for _,_,lo,hi in sorted(group,key=lambda s:s[2]):
   if intervals and lo<=intervals[-1][1]+.015:intervals[-1][1]=max(hi,intervals[-1][1])
   else:intervals.append([lo,hi])
  for a,b in zip(intervals,intervals[1:]):
   width=b[0]-a[1]
   if .1<width<2.5:
    center=np.zeros(3);center[1]=y;center[axis]=np.mean([s[1] for s in group]);center[2 if axis==0 else 0]=(a[1]+b[0])/2
    up=rays(tri,center,[0,1,0]);floor=rays(tri,center,[0,-1,0]);gaps.append({'axis':axis,'plane':float(center[axis]),'start':a[1],'end':b[0],'width':width,'center':center.tolist(),'floor_y':float(y-floor.min()) if len(floor) else None,'ceiling_y':float(y+up.min()) if len(up) else None,'height':float(up.min()+floor.min()) if len(up) and len(floor) else None})
(root/'opening_candidates.json').write_text(json.dumps(gaps,indent=2));print('GAPS',gaps)
# Original glTF material backface flags.
p=Path('/workspace/attachments/b08da96f-4bc3-46d2-a7e0-2a004e3d0dc7/warehouse_fbx_model_free.glb');b=p.read_bytes();size=struct.unpack_from('<I',b,12)[0];g=json.loads(b[20:20+size]);print('MATERIALS',[(m.get('name'),m.get('doubleSided',False)) for m in g['materials']])
(root/'warehouse_materials.json').write_text(json.dumps(g['materials'],indent=2))
