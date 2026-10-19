"""Step D: geometric coverage mask, excluding protected seams; no texture painting."""
import json,sys
from pathlib import Path
import numpy as np
from mathutils import Vector
from mathutils.bvhtree import BVHTree
from mathutils.kdtree import KDTree
args=sys.argv[sys.argv.index('--')+1:]
data=json.loads(Path(args[0]).read_text());patch=json.loads(Path(args[1]).read_text());heat=json.loads(Path(args[2]).read_text());out=Path(args[3]);out.mkdir(parents=True,exist_ok=True)
cfg=json.loads((Path(__file__).resolve().parents[2]/'data/clipping/audit_settings.json').read_text())
body=data['meshes'][0];edit=patch['meshes'][body['name']];v=np.array(edit['v']);protected=np.array(edit['protected']);gv=[];gf=[]
for m in data['meshes'][1:]:
 p=patch['meshes'][m['name']]['v'];gf.extend((np.array(m['indices']).reshape(-1,3)+len(gv)).tolist());gv.extend(p)
bvh=BVHTree.FromPolygons(gv,gf,all_triangles=True)
covered=np.zeros(len(v),dtype=bool)
for i,p in enumerate(v):
 if protected[i] or heat['labels'][i]=='excluded':continue
 q,n,f,d=bvh.find_nearest(Vector(p),cfg['covered_mask_shell_distance_mm']/1000)
 covered[i]=q is not None
# Expand only within the authored covered region, without crossing protected seams.
k=KDTree(int(covered.sum()))
for j,i in enumerate(np.flatnonzero(covered)):k.insert(Vector(v[i]),j)
k.balance()
for i,p in enumerate(v):
 if not protected[i] and heat['labels'][i]!='excluded':
  _,_,d=k.find(Vector(p));covered[i]|=d<=cfg['covered_mask_margin_mm']/1000
regions=['neck_collar','chest','abdomen','shoulders','elbows','wrists','hips','knees','ankles','excluded']
edit['covered']=covered.astype(int).tolist();edit['zones']=[regions.index(x) for x in heat['labels']]
patch['stage']='D_covered_skin_mask';(out/'patch.json').write_text(json.dumps(patch))
report={'covered_vertices':int(covered.sum()),'protected_vertices_hidden':int((covered&protected).sum()),'region_ids':dict(enumerate(regions)),'coverage_shell_distance_mm':cfg['covered_mask_shell_distance_mm'],'safety_margin_mm':cfg['covered_mask_margin_mm'],'limitations':['Mask is only for this fitted kit, not transferable to bare-sleeve roles','Protected cut bands remain visible; local lining still required','Region reveal is diagnostic, not a fitted gear tear state']}
(out/'mask_report.json').write_text(json.dumps(report,indent=2));print(json.dumps(report))
