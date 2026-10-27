"""Sample the remade openings against actual triangle geometry (not physics acceptance)."""
from pathlib import Path
import json,sys,numpy as np
root=Path(sys.argv[1]);d=np.load(root/'killhouse_step1.npz');report=json.loads((root/'step1_geometry.json').read_text());S=report['config']['layout_scale'];center=np.array(report['original_bounds_center_raw']);F=report['config']['floor_raw_y']
tri=d['Object_16_v'][d['Object_16_f']]
def world(raw):
 v=(np.array(raw)-np.array([center[0],F,center[2]]))*S
 return np.array([v[2],v[1],-v[0]])
def intersect(o,end):
 direction=end-o;e1=tri[:,1]-tri[:,0];e2=tri[:,2]-tri[:,0];h=np.cross(direction,e2);a=np.einsum('ij,ij->i',e1,h);mask=np.abs(a)>1e-10;inv=np.zeros_like(a);inv[mask]=1/a[mask];s=o-tri[:,0];u=inv*np.einsum('ij,ij->i',s,h);q=np.cross(s,e1);v=inv*(q@direction);t=inv*np.einsum('ij,ij->i',e2,q)
 return bool(np.any(mask&(u>=0)&(v>=0)&(u+v<=1)&(t>1e-6)&(t<.999999)))
doors=[('west room',0,-2.82,.00415),('east room',0,2.44,.039298345),('left cell front',2,-.96,-.8030932),('right cell front',2,-.96,.15261895),('left cell side',0,-1.215,-1.6163),('right cell side',0,.715,-1.6163),('cell divider',0,-.2455,-1.4324),('north mantle notch',0,1.615,1.284)]
results=[]
for name,axis,plane,lateral in doors:
 failed=[]
 min_y,max_y=(1.25,2.75) if "notch" in name else (.03,2.07)
 for offset in np.linspace(-.515,.515,23):
  for height in np.linspace(min_y,max_y,35):
   raw=np.zeros(3);raw[1]=F+height/S;raw[axis]=plane;raw[2 if axis==0 else 0]=lateral+offset/S
   a=raw.copy();b=raw.copy();a[axis]-=.05;b[axis]+=.05
   if intersect(world(a),world(b)):failed.append([float(offset),float(height)])
 results.append({'name':name,'raw_plane_axis':axis,'raw_plane':plane,'raw_lateral_center':lateral,'sampled_width_m':1.03,'sampled_height_range_m':[min_y,max_y],'samples':805,'blocked_samples':len(failed),'first_blocked':failed[:6]})
(root/'opening_validation.json').write_text(json.dumps(results,indent=2)+'\n')
print(json.dumps(results,indent=2))
if any(r['blocked_samples'] for r in results):raise SystemExit(1)
