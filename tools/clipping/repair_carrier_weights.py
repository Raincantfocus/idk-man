"""Local repair F: respect the purchased carrier's anatomical attachment region."""
import json,sys
from pathlib import Path
import numpy as np
args=sys.argv[sys.argv.index('--')+1:];data=json.loads(Path(args[0]).read_text());patch=json.loads(Path(args[1]).read_text());out=Path(args[2]);out.mkdir(parents=True,exist_ok=True)
m=next(m for m in data['meshes'] if m['name']=='complete_kit');edit=patch['meshes'][m['name']];w=np.array(edit['w']);j=np.array(edit['j']);old_w=np.array(m['weights']).reshape(-1,4);old_j=np.array(m['joints']).reshape(-1,4);names=np.array([data['bones'][i] for i in m['bind_bones']]);changed=0;fallback=0
for i in range(len(w)):
 owner=names[old_j[i,np.argmax(old_w[i])]]
 if owner in ['Spine','Chest','UpperChest','Neck','LeftShoulder','RightShoulder']:
  allowed=['Spine','Chest','UpperChest',owner] # Do not bind torso-mounted pouches to an adjacent arm.
 elif owner=='Hips':allowed=['Hips','Spine','LeftUpperLeg','RightUpperLeg','LeftUpperLegTwist','RightUpperLegTwist']
 else:
  side='Left' if owner.startswith('Left') else 'Right';allowed=['Hips',side+'UpperLeg',side+'UpperLegTwist',side+'LowerLeg',side+'LowerLegTwist']
 keep=np.array([n in allowed for n in names[j[i]]]);filtered=w[i]*keep
 if np.allclose(filtered,w[i]):continue
 changed+=1
 if filtered.sum()<1e-6:w[i]=old_w[i]/old_w[i].sum();j[i]=old_j[i];fallback+=1
 else:w[i]=filtered/filtered.sum()
edit['w']=w.tolist();edit['j']=j.tolist()
# Rebuild this garment's conservative correctives using the repaired joint weights.
for rule in patch['corrective_rules']:
 target=data['bones'].index(rule['bone']);strength=np.zeros(len(w))
 for slot in range(4):strength+=w[:,slot]*(np.array(m['bind_bones'])[j[:,slot]]==target)
 edit['correctives'][rule['name']]=(np.array(m['normals'])*strength[:,None]*.003).tolist()
patch['stage']='F_carrier_attachment_repair';(out/'patch.json').write_text(json.dumps(patch));report={'changed_vertices':changed,'source_weight_fallback_vertices':fallback,'max_normalization_error':float(abs(w.sum(axis=1)-1).max()),'method':'Constrain transferred influences to original anatomical attachment region; prevent nearby arm weights moving torso-mounted pouches','approved':False};(out/'carrier_report.json').write_text(json.dumps(report,indent=2));print(report)
