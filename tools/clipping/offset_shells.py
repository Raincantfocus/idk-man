"""Step B: outward-only garment clearance in original bind space."""
import json,sys
import numpy as np
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
from mathutils.kdtree import KDTree
args=sys.argv[sys.argv.index('--')+1:];data=json.loads(Path(args[0]).read_text());patch=json.loads(Path(args[1]).read_text());out=Path(args[2]);out.mkdir(parents=True,exist_ok=True)
cfg=json.loads((Path(__file__).resolve().parents[2]/'data/clipping/audit_settings.json').read_text());body=data['meshes'][0];bv=np.array(body['vertices']);bn=np.array(body['normals']);faces=np.array(body['indices']).reshape(-1,3)
bvh=BVHTree.FromPolygons(bv.tolist(),faces.tolist(),all_triangles=True);kd=KDTree(len(bv))
for i,p in enumerate(bv):kd.insert(Vector(p),i)
kd.balance();reports={}
for m in data['meshes'][1:]:
 edit=patch['meshes'][m['name']];v=np.array(edit.get('v',m['vertices']));normals=np.array(m['normals']);w=np.array(edit['w']);j=np.array(edit['j']);result=v.copy();moves=[];targets=[];clamped=0
 for i,p in enumerate(v):
  q,n,face,distance=bvh.find_nearest(Vector(p));_,nearest,_=kd.find(q);normal=normals[i].copy()
  if normal@bn[nearest]<0:normal=-normal
  normal/=max(np.linalg.norm(normal),1e-8);surface_normal=np.array(n)
  if surface_normal@bn[nearest]<0:surface_normal=-surface_normal
  bone=data['bones'][m['bind_bones'][j[i,np.argmax(w[i])]]]
  small=any(x in bone for x in ['Hand','Foot','Toes','Thumb','Index','Middle','Ring','Little'])
  target=cfg['offset_mm']['armor' if m['name']=='complete_kit' else 'boot_glove' if small else 'jacket']/1000
  signed=(p-np.array(q))@surface_normal
  requested=max(0,(target-signed)/max(.25,normal@surface_normal))
  # A nearest tangent plane is unreliable across folds and adjacent limbs.
  # Bound the adjustment; leave deep fitting errors for explicit local repair.
  amount=min(target,requested);clamped+=int(requested>target)
  result[i]+=normal*amount;moves.append(amount);targets.append(target)
 edit['v']=result.tolist();reports[m['name']]={'vertices':len(v),'moved_vertices':int(sum(x>1e-8 for x in moves)),'max_outward_displacement_mm':max(moves)*1000,'mean_outward_displacement_mm':float(np.mean(moves))*1000,'target_clearance_mm':sorted(set(round(x*1000,3) for x in targets)),'clamped_vertices':clamped,'method':'bounded outward-only, initial nearest tangent-plane clearance; posed BVH rerun determines acceptance'}
patch['stage']='B_outward_clearance';(out/'patch.json').write_text(json.dumps(patch));(out/'offset_report.json').write_text(json.dumps(reports,indent=2));print(json.dumps(reports),flush=True)
