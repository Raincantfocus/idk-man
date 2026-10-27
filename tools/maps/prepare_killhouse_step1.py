"""Derive Step-1 review geometry from the Step-0 measured arrays, never source files.
python tools/maps/prepare_killhouse_step1.py /workspace/map-intake OUTPUT_DIR
Only geometry edits/scale/orientation: no warehouse placement or runtime hookup.
"""
from pathlib import Path
import json,sys,numpy as np
from scipy.sparse import coo_matrix
from scipy.sparse.csgraph import connected_components
root=Path(sys.argv[1]);out=Path(sys.argv[2]);out.mkdir(parents=True,exist_ok=True)
repo=Path(__file__).resolve().parents[2];cfg=json.loads((repo/'data/maps/killhouse_step1.json').read_text())
data=np.load(root/'killhouse.npz');rows=json.loads((root/'killhouse.json').read_text());floor=cfg['floor_raw_y'];S=cfg['layout_scale'];copies={};changes=[]
center=(np.min([r['min'] for r in rows],0)+np.max([r['max'] for r in rows],0))/2

def interpolate_extrapolate(a,x,y):
 b=np.interp(a,x,y)
 b=np.where(a<x[0],y[0]+(a-x[0])*(y[1]-y[0])/(x[1]-x[0]),b)
 b=np.where(a>x[-1],y[-1]+(a-x[-1])*(y[-1]-y[-2])/(x[-1]-x[-2]),b)
 return b

def widen(v,axis,lo,hi,mask=None):
 if mask is None:mask=np.ones(len(v),bool)
 selected=v[mask,axis];mn,mx=v[:,axis].min(),v[:,axis].max();mid=(lo+hi)/2;half=cfg['door_width_m']/S/2
 assert mn<mid-half and mid+half<mx,(mn,mx,mid,half)
 v[mask,axis]=interpolate_extrapolate(selected,[mn,lo,hi,mx],[mn,mid-half,mid+half,mx])

for row in rows:
 name=row['name'];v=data[row['key']+'_v'].copy();f=data[row['key']+'_f'].copy()
 if name=='Object_16':
  uv,inv=np.unique(np.round(v,5),axis=0,return_inverse=True);fi=inv[f];e=np.concatenate([fi[:,[0,1]],fi[:,[1,2]],fi[:,[2,0]]]);_,labels=connected_components(coo_matrix((np.ones(len(e)),(e[:,0],e[:,1])),shape=(len(uv),len(uv))),directed=False);vl=labels[inv]
  partition_ids=[17,18,32,41,43,44,45,46,47,66,70,71,93,94]
  room_ids=[19,20,21,72,74,75]
  for component in partition_ids+room_ids+[48,65]:
   mask=vl==component;p=v[mask].copy();old=p.copy();top=p[:,1].max()
   if component in room_ids:
    p[:,1]=interpolate_extrapolate(p[:,1],[floor,.20058975,.26475,.37902],[floor,floor+cfg['door_height_m']/S,floor+cfg['partition_height_m']/S,floor+cfg['room_peak_height_m']/S])
   elif component in [48,65]:
    p[:,1]=interpolate_extrapolate(p[:,1],[-.0234818,.30812753,.32091391,.3949732],[floor,floor+cfg['door_height_m']/S,floor+(cfg['door_height_m']+.08)/S,floor+cfg['partition_height_m']/S])
   else:p[:,1]=floor+(p[:,1]-floor)*(cfg['partition_height_m']/S)/(top-floor)
   if component==19:widen(p,2,-.1078,.1161,p[:,0]<-2.78)
   if component==72:widen(p,2,-.07267037,.15126706,p[:,0]>2.40)
   if component==48:
    maskfront=p[:,2]>-1.0
    widen(p,0,-.9697203,-.6364661,maskfront & (p[:,0]<-.3))
    widen(p,0,-.01400815,.31924605,maskfront & (p[:,0]>-.20))
    widen(p,2,-1.7578,-1.4748,(p[:,0]<-1.18)|(p[:,0]>.68))
   if component==65:widen(p,2,-1.5739,-1.2909)
   if component==71:widen(p,2,1.1477,1.4203)
   if component==93:
    old_end=p[:,2].max();new_end=-.65955348-cfg['door_width_m']/S
    p[:,2]=interpolate_extrapolate(p[:,2],[p[:,2].min(),old_end],[p[:,2].min(),new_end])
   v[mask]=p
   changes.append({'object':name,'component':component,'vertices':int(mask.sum()),'before_min':old.min(0).tolist(),'before_max':old.max(0).tolist(),'after_min':p.min(0).tolist(),'after_max':p.max(0).tolist()})
 # Only uniform layout scale + 90-degree rotation; no warehouse translation.
 v[:,0]-=center[0];v[:,2]-=center[2];v[:,1]-=floor;v*=S
 v=v[:,[2,1,0]];v[:,2]*=-1
 copies[name+'_v']=v;copies[name+'_f']=f
# Props: use principal horizontal axis to measure car length, avoiding rotated AABB errors.
v=copies['Object_4_v'];c=v.mean(0);horizontal=v[:,[0,2]]-c[[0,2]];_,_,basis=np.linalg.svd(horizontal,full_matrices=False);extent=np.ptp(horizontal@basis.T,axis=0);ratio=cfg['car_length_m']/extent[0]
v=(v-c)*ratio+c;v[:,1]-=v[:,1].min();copies['Object_4_v']=v
changes.append({'object':'Object_4','uniform_prop_factor_after_layout_scale':float(ratio),'oriented_before_length_m':float(extent[0]),'oriented_after_length_m':cfg['car_length_m']})
stack_y=0.0
for number in range(18,23):
 key=f'Object_{number}_v';v=copies[key];c=(v.min(0)+v.max(0))/2;ratio=cfg['pallet_long_side_m']/max(np.ptp(v[:,[0,2]],axis=0));v=(v-c)*ratio+c;v[:,1]+=stack_y-v[:,1].min();stack_y=v[:,1].max()+cfg['pallet_stack_gap_m'];copies[key]=v
 changes.append({'object':f'Object_{number}','uniform_prop_factor_after_layout_scale':float(ratio),'stack_bottom_m':float(v[:,1].min()),'stack_top_m':float(v[:,1].max())})
# Upright repeated pieces use their longest principal axis, preserving proportions.
for number in [17,23,24]:
 key=f'Object_{number}_v';v=copies[key];c=v.mean(0);_,_,b=np.linalg.svd(v-c,full_matrices=False);ext=np.ptp((v-c)@b.T,axis=0);ratio=cfg['pallet_long_side_m']/max(ext);v=(v-c)*ratio+c;v[:,1]-=v[:,1].min();copies[key]=v
 changes.append({'object':f'Object_{number}','uniform_prop_factor_after_layout_scale':float(ratio),'longest_principal_extent_m':cfg['pallet_long_side_m'],'placement_warning':'upright group spacing requires Step 2 adjustment'})
np.savez_compressed(out/'killhouse_step1.npz',**copies)
report={'config':cfg,'original_bounds_center_raw':center.tolist(),'changes':changes,'meshes':[]}
for row in rows:
 name=row['name'];v=copies[name+'_v'];report['meshes'].append({'name':name,'triangles':len(copies[name+'_f']),'min':v.min(0).tolist(),'max':v.max(0).tolist()})
report['all_bounds_min']=np.min([r['min'] for r in report['meshes']],0).tolist();report['all_bounds_max']=np.max([r['max'] for r in report['meshes']],0).tolist()
(out/'step1_geometry.json').write_text(json.dumps(report,indent=2)+'\n');print('STEP1_GEOMETRY',report['all_bounds_min'],report['all_bounds_max'])
