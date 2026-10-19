"""Conservative clearance correctives, not approved anatomical muscle correctives."""
import json,sys
from pathlib import Path
import numpy as np
args=sys.argv[sys.argv.index('--')+1:];data=json.loads(Path(args[0]).read_text());patch=json.loads(Path(args[1]).read_text());parents=json.loads(Path(args[2]).read_text());out=Path(args[3]);out.mkdir(parents=True,exist_ok=True)
cfg=json.loads((Path(__file__).resolve().parents[2]/'data/clipping/corrective_rules.json').read_text());rules=cfg['rules']
assert all(r['bone'] in data['bones'] for r in rules)
for m in data['meshes']:
 edit=patch['meshes'][m['name']];w=np.array(edit.get('w',m['weights'])).reshape(len(m['vertices']),-1);j=np.array(edit.get('j',m['joints'])).reshape(len(m['vertices']),-1);normals=np.array(m['normals']);edit['correctives']={}
 for rule in rules:
  target=data['bones'].index(rule['bone']);strength=np.zeros(len(w))
  for slot in range(w.shape[1]):strength+=w[:,slot]*(np.array(m['bind_bones'])[j[:,slot]]==target)
  amount=cfg['body_delta_mm' if m==data['meshes'][0] else 'gear_delta_mm']/1000
  if m==data['meshes'][0]:strength[np.array(edit['protected'])]=0
  edit['correctives'][rule['name']]=(normals*strength[:,None]*amount).tolist()
patch['stage']='E_clearance_corrective_candidates';patch['corrective_rules']=rules;patch['bone_parents']=parents;patch['corrective_near_distance_m']=cfg['near_distance_m']
(out/'patch.json').write_text(json.dumps(patch));(out/'corrective_report.json').write_text(json.dumps({'rules':rules,'shape_count_per_mesh':len(rules),'body_max_delta_mm':2,'gear_max_delta_mm':3,'near_distance_m':8,'approved':False,'limitation':'Normal-offset clearance candidates weighted to joints; not artist-sculpted anatomy. Acceptance depends on posed audit and visual review.'},indent=2));print('CORRECTIVES_AUTHORED',len(rules))
