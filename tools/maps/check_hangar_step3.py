"""Validate reimported Step 3 arrays: script ARRAYS ROWS OUTPUT_JSON."""
import sys,json,numpy as np
from pathlib import Path
a=np.load(sys.argv[1]);rows=json.loads(Path(sys.argv[2]).read_text());tris=[];below=[];floors=[]
for row in rows:
 v=a[row['key']+'_v'];t=v[a[row['key']+'_f']];tris.append(t)
 if row['name'].startswith('Killhouse_'):
  if v[:,1].min() < -1e-5:below.append(row['name'])
  count=int(np.all(np.abs(t[:,:,1])<.001,axis=1).sum())
  if count:floors.append({'mesh':row['name'],'triangles':count})
t=np.concatenate(tris);results=[]
for name,z,w,h,depth in [('north',-12,1.2,2.2,1.6),('south',-34.5,1.2,2.2,1.6),('warehouse_entry',0,7.7,2.8,.4)]:
 # Ray from either side of finite opening prism, all actual exported meshes.
 keep=(t[:,:,0].max(1)>=8-w/2)&(t[:,:,0].min(1)<=8+w/2)&(t[:,:,1].min(1)<=h)&(t[:,:,2].min(1)<=z+depth/2)&(t[:,:,2].max(1)>=z-depth/2)
 q=t[keep];e1=q[:,1]-q[:,0];e2=q[:,2]-q[:,0];direction=np.array([0,0,1]);p=np.cross(np.broadcast_to(direction,e2.shape),e2);det=np.einsum('ij,ij->i',e1,p);valid=np.abs(det)>1e-9;inv=np.divide(1,det,out=np.zeros_like(det),where=valid);blocked=0
 for x in np.linspace(8-w/2+.01,8+w/2-.01,23):
  for y in np.linspace(.03,h-.03,35):
   s=np.array([x,y,z-depth/2])-q[:,0];u=np.einsum('ij,ij->i',s,p)*inv;cross=np.cross(s,e1);v=cross@direction*inv;distance=np.einsum('ij,ij->i',e2,cross)*inv
   hit=valid&(u>=0)&(v>=0)&(u+v<=1)&(distance>=0)&(distance<=depth)
   blocked+=int(hit.any())
 results.append({'opening':name,'samples':805,'blocked':blocked,'tested_triangles':len(q),'sampled_width_m':w-.02,'sampled_y_m':[.03,h-.03]})
report={'reimported_triangles':len(t),'meshes':len(rows),'killhouse_below_floor':below,'killhouse_coplanar_floor_triangles':floors,'openings':results,'physics_capsule_sweeps':False}
Path(sys.argv[3]).write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2))
assert not below and not floors
assert all(r['blocked']==0 for r in results)
