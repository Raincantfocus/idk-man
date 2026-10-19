"""Step C: bounded inward body adjustment; freeze cut bands and neck vertices."""
import json,sys,hashlib
import numpy as np
from pathlib import Path
from mathutils import Vector
from mathutils.kdtree import KDTree
args=sys.argv[sys.argv.index('--')+1:];data=json.loads(Path(args[0]).read_text());patch=json.loads(Path(args[1]).read_text());heat=json.loads(Path(args[2]).read_text());cuts=json.loads(Path(args[3]).read_text());out=Path(args[4]);out.mkdir(parents=True,exist_ok=True)
cfg=json.loads((Path(__file__).resolve().parents[2]/'data/clipping/audit_settings.json').read_text());body=data['meshes'][0];v=np.array(body['vertices']);n=np.array(body['normals']);labels=heat['labels'];protected=np.array([x in ['neck_collar','excluded'] for x in labels])
def godot(p):return np.array([p[0],p[2],-p[1]])
for region in cuts['regions'].values():
 center=godot(region['center_blender']);axis=godot(region['basis_blender'][2])
 for side in [1,-1]:
  c=center.copy();a=axis.copy();c[0]*=side;a[0]*=side
  protected|=np.abs((v-c)@a)<cfg['seam_lock_band_mm']/1000
kd=KDTree(int(protected.sum()))
for j,i in enumerate(np.flatnonzero(protected)):kd.insert(Vector(v[i]),j)
kd.balance();amount=np.clip(np.array(heat['max_heat_m'])+.002,cfg['body_shrink_min_mm']/1000,cfg['body_shrink_max_mm']/1000)
# Expand seam-duplicate values before applying a common falloff.
groups={}
for i,p in enumerate(v):groups.setdefault(tuple(np.round(p,6)),[]).append(i)
for ids in groups.values():amount[ids]=max(amount[ids]);protected[ids]=any(protected[ids])
for i,p in enumerate(v):
 _,_,distance=kd.find(Vector(p));t=min(1,distance/(cfg['body_falloff_mm']/1000));amount[i]*=t*t*(3-2*t)
amount[protected]=0;result=v-n*amount[:,None]
patch['meshes']['Body_LOD0']={'v':result.tolist(),'protected':protected.tolist()};patch['stage']='C_protected_body_shrink'
report={'protected_vertices':int(protected.sum()),'protected_position_max_delta_mm':float(np.linalg.norm((result-v)[protected],axis=1).max())*1000,'max_inward_mm':float(amount.max())*1000,'mean_inward_mm':float(amount.mean())*1000,'cut_families_locked':list(cuts['regions']),'neck_and_head_locked':True,'raw_protected_sha256_before':hashlib.sha256(v[protected].tobytes()).hexdigest(),'raw_protected_sha256_after':hashlib.sha256(result[protected].tobytes()).hexdigest(),'limitation':'Conservative source cut-plane bands, including mirrored right cuts; no claim of fitted cloth cut edges'}
(out/'patch.json').write_text(json.dumps(patch));(out/'shrink_report.json').write_text(json.dumps(report,indent=2));print(json.dumps(report),flush=True)
