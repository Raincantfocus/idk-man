"""Step A only: BVH barycentric body-weight transfer, smoothing, four influences."""
import bpy,json,sys
import numpy as np
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
args=sys.argv[sys.argv.index('--')+1:];data=json.loads(Path(args[0]).read_text());out=Path(args[1]);out.mkdir(parents=True,exist_ok=True)
config=json.loads((Path(__file__).resolve().parents[2]/'data/clipping/audit_settings.json').read_text())
def matrices(rows):
 m=np.zeros((len(rows),4,4));m[:,:3,:]=np.array(rows).reshape(-1,3,4);m[:,3,3]=1;return m
rest=matrices(data['rests']);body=data['meshes'][0];count=len(data['bones'])
def unpack(m):
 v=np.array(m['vertices']);w=np.array(m['weights']).reshape(len(v),-1);j=np.array(m['joints'],int).reshape(len(v),-1);mapping=np.array(m['bind_bones']);bind=matrices(m['binds']);transforms=rest[mapping]@bind
 p=np.c_[v,np.ones(len(v))];r=sum(np.einsum('nij,nj->ni',transforms[j[:,k],:3,:],p)*w[:,k,None] for k in range(w.shape[1]))
 full=np.zeros((len(v),count))
 for k in range(w.shape[1]):np.add.at(full,(np.arange(len(v)),mapping[j[:,k]]),w[:,k])
 return v,full,mapping
bv,bw,_=unpack(body);faces=np.array(body['indices']).reshape(-1,3);bvh=BVHTree.FromPolygons(bv.tolist(),faces.tolist(),all_triangles=True)
patch={'stage':'A_weights','meshes':{}};report={}
for m in data['meshes'][1:]:
 v,old,mapping=unpack(m);target=np.zeros_like(old)
 for i,p in enumerate(v):
  near,normal,index,distance=bvh.find_nearest(Vector(p));a,b,c=bv[faces[index]];v0=b-a;v1=c-a;v2=np.array(near)-a
  d00=v0@v0;d01=v0@v1;d11=v1@v1;d20=v2@v0;d21=v2@v1;den=d00*d11-d01*d01
  t=(d11*d20-d01*d21)/den if abs(den)>1e-15 else 0;s=(d00*d21-d01*d20)/den if abs(den)>1e-15 else 0
  bary=np.clip([1-t-s,t,s],0,1);bary/=sum(bary);target[i]=bary@bw[faces[index]]
 result=target.copy();adj=[set() for _ in v]
 for f in np.array(m['indices']).reshape(-1,3):
  for a,b in [(f[0],f[1]),(f[1],f[2]),(f[2],f[0])]:adj[a].add(b);adj[b].add(a)
 factor=config['weight_smoothing_factor']
 for _ in range(config['weight_smoothing_iterations']):
  result=np.array([(1-factor)*result[i]+factor*result[list(neighbors)].mean(axis=0) if neighbors else result[i] for i,neighbors in enumerate(adj)])
 top=np.argsort(result,axis=1)[:,-config['max_influences']:];weights=np.take_along_axis(result,top,axis=1);weights/=weights.sum(axis=1)[:,None]
 inverse={bone:i for i,bone in enumerate(mapping)};joints=np.array([[inverse[int(b)] for b in row] for row in top]);new=np.zeros_like(result)
 for k in range(4):np.add.at(new,(np.arange(len(v)),top[:,k]),weights[:,k])
 before=np.abs(old-target).sum(axis=1);after=np.abs(new-target).sum(axis=1)
 patch['meshes'][m['name']]={'w':weights.tolist(),'j':joints.tolist()}
 report[m['name']]={'vertices':len(v),'before_mismatch_vertices':int(sum(before>config['weight_mismatch_l1_threshold'])),'after_mismatch_vertices':int(sum(after>config['weight_mismatch_l1_threshold'])),'before_mean_l1':float(before.mean()),'after_mean_l1':float(after.mean()),'before_max_l1':float(before.max()),'after_max_l1':float(after.max()),'max_influences':4,'max_normalization_error':float(abs(weights.sum(axis=1)-1).max())}
(out/'patch.json').write_text(json.dumps(patch));(out/'weight_report.json').write_text(json.dumps(report,indent=2));print(json.dumps(report),flush=True)
