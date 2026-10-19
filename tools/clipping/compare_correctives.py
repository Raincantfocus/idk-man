import json,sys,math
from pathlib import Path
import numpy as np
root=Path(sys.argv[1]);data=json.loads((root/'baseline_input.json').read_text());patch=json.loads((root/'stage_e/patch.json').read_text());actual=json.loads((root/'stage_e/native_weights.json').read_text())
def matrices(rows):
 a=np.array(rows).reshape(-1,3,4);out=np.zeros((len(a),4,4));out[:,:3,:]=a;out[:,3,3]=1;return out
rest=matrices(data['rests']);poses={(c['name'],s['frame']):s for c in data['clips'] for s in c['samples']};errors=[]
for row in actual:
 pose=matrices(poses[(row['clip'],row['frame'])]['bones'])
 for rule in patch['corrective_rules']:
  bone=data['bones'].index(rule['bone']);parent=patch['bone_parents'][bone];local=np.linalg.inv(pose[parent])@pose[bone];r=np.linalg.inv(np.linalg.inv(rest[parent])@rest[bone])@local;r=r[:3,:3]
  angle=abs(math.atan2(r[0,2],r[2,2])) if rule['axis']=='yaw' else math.acos(float(np.clip((np.trace(r)-1)/2,-1,1)))
  t=float(np.clip((math.degrees(angle)-rule['start_degrees'])/(rule['full_degrees']-rule['start_degrees']),0,1));t=t*t*(3-2*t);errors.append(abs(row['weights'][rule['name']]-t))
assert max(errors)<1e-4,max(errors)
report={'compared_weights':len(errors),'max_absolute_error':max(errors),'far_reset_native_pass':True}
(root/'stage_e/corrective_test_report.json').write_text(json.dumps(report,indent=2));print(report)
