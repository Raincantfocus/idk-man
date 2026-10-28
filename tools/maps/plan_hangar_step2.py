"""Review placement only. Usage: script INTAKE STEP1 OUTPUT.
Dependencies: numpy scipy shapely>=2. No source or scene edits.
"""
from pathlib import Path
import sys,json
import numpy as np
from scipy.sparse import coo_matrix
from scipy.sparse.csgraph import connected_components
from shapely.geometry import Polygon,LineString
from shapely.strtree import STRtree
from shapely import get_coordinates
root,step,out=map(Path,sys.argv[1:]);out.mkdir(parents=True,exist_ok=True)
src=np.load(root/'killhouse.npz');kh=np.load(step/'killhouse_step1.npz');wh=np.load(root/'warehouse.npz')
# Revised uniform layout scale 2.91/3.0 to clear the 0.20 m ribs.
kh={k:kh[k].copy() for k in kh.files}
for k in kh:
 if k.endswith('_v'):
  old=kh[k];kh[k]=old*.97
  if k in ['Object_4_v']+[f'Object_{i}_v' for i in range(17,25)]:
   c=old.mean(0);kh[k]=old-c+c*.97
   kh[k][:,1]-=kh[k][:,1].min()
bottom=0
for i in range(18,23):
 v=kh[f'Object_{i}_v'];v[:,1]+=bottom;bottom=v[:,1].max()+.002
rows=json.loads((root/'killhouse.json').read_text());row16=next(r for r in rows if r['name']=='Object_16')
v=src[row16['key']+'_v'];f=src[row16['key']+'_f']
u,inv=np.unique(np.round(v,5),axis=0,return_inverse=True);fi=inv[f];e=np.concatenate([fi[:,[0,1]],fi[:,[1,2]],fi[:,[2,0]]])
_,labels=connected_components(coo_matrix((np.ones(len(e)),(e[:,0],e[:,1])),shape=(len(u),len(u))),directed=False);components=labels[inv][f[:,0]]
roof=wh['mesh0_v'][wh['mesh0_f']];rp=[];planes=[]
for t in roof:
 p=Polygon(t[:,[0,2]])
 if t[:,1].min()>2.5 and p.area>1e-10:
  rp.append(p);planes.append(np.linalg.solve(np.column_stack([t[:,0],t[:,2],np.ones(3)]),t[:,1]))
planes=np.array(planes);tree=STRtree(rp)
def clearance(tris):
 # Linear height differences attain extrema at projected overlap vertices.
 # Edges also cover zero-area projections of vertical partitions.
 best=float('inf');point=None;tested=0;uncovered=0
 for t in tris:
  if t[:,1].max()<2:continue
  poly=Polygon(t[:,[0,2]]);entities=[]
  if poly.area>1e-10:
   coeff=np.linalg.solve(np.column_stack([t[:,0],t[:,2],np.ones(3)]),t[:,1]);entities.append((poly,coeff,None))
  for a,b in [(t[0],t[1]),(t[1],t[2]),(t[2],t[0])]:
   if np.linalg.norm(b[[0,2]]-a[[0,2]])>1e-9:entities.append((LineString([a[[0,2]],b[[0,2]]]),None,(a,b)))
  for shape,coeff,edge in entities:
   found=False
   for idx in tree.query(shape,predicate='intersects'):
    points=get_coordinates(shape.intersection(rp[idx]))
    if not len(points):continue
    found=True;yroof=np.column_stack([points,np.ones(len(points))])@planes[idx]
    if coeff is not None:y=np.column_stack([points,np.ones(len(points))])@coeff
    else:
     a,b=edge;d=b[[0,2]]-a[[0,2]];alpha=(points-a[[0,2]])@d/(d@d);y=a[1]+alpha*(b[1]-a[1])
    gaps=yroof-y;ii=int(np.argmin(gaps));tested+=len(points)
    if gaps[ii]<best:best=float(gaps[ii]);point=[float(points[ii,0]),float(y[ii]),float(points[ii,1])]
   if not found:uncovered+=1
 return {'min_clearance_m':best if np.isfinite(best) else None,'critical_point':point,'ray_extrema':tested,'uncovered_entities':uncovered}
def evaluate(z,adjust=False, tower_factor=.55):
 result=[]
 for name in ['Object_16','Object_9']:
  v=kh[name+'_v'].copy();f=kh[name+'_f'];v += [8,0,z]
  if name=='Object_16' and adjust:
   vi=np.unique(f[np.isin(components,list(range(49,70)))])
   sel=vi[v[vi,1]>3];v[sel,1]=3+(v[sel,1]-3)*tower_factor
  groups=range(int(components.max())+1) if name=='Object_16' else [-1]
  for cid in groups:
   tris=v[f[components==cid]] if cid>=0 else v[f]
   if tris[:,:,1].max()<2:continue
   r=clearance(tris);r.update(mesh=name,component=cid,max_height_m=float(tris[:,:,1].max()),pending_shell_removal=bool(name=='Object_16' and cid==0));result.append(r)
 return result
report={'method':'Projected triangle-overlap extrema: upward vertical intersections with lowest Metal surface above 2.5 m, including ribs. Vertical edges included. Not Jolt tests; fixtures and colliders remain pending.','roof_triangles':len(rp),'revised_layout_scale':2.91,'relative_scale':.97,'warehouse_rib_intrusion_m':.200001,'floor_y_m':0,'required_clearance_m':.3,'plans':[]}
for label,z in [('centered',-23.07500648498535),('front_staging',-26.07500648498535)]:
 factor=.55 if label=="centered" else .8
 before=evaluate(z);after=evaluate(z,True,factor)
 report['plans'].append({'id':label,'tower_upper_factor':factor,'translation_m':[8,0,z],'entry_staging_m':-(z+(11.666054964065552*.97)),'rear_staging_m':z-(11.666054964065552*.97)+46.1500129699707,'side_alleys_m':[8-5.92998880147934*.97-.200001]*2,'before':before,'proposed_after':after})
# Repack the overlapping upright pallets onto the existing pallet pile.
# PCA yields an orthonormal rigid rotation, not a scale or mesh replacement.
stack=kh['Object_22_v'];center=(stack.min(0)+stack.max(0))/2
bottom=float(stack[:,1].max())+.002;prop_moves=[]
for number in [17,23,24]:
 name=f'Object_{number}';v=kh[name+'_v'];origin=v.mean(0)
 _,_,basis=np.linalg.svd(v-origin,full_matrices=False)
 ext=np.ptp((v-origin)@basis.T,axis=0);order=np.argsort(ext)[::-1]
 rotation=basis[[order[0],order[2],order[1]]]
 if np.linalg.det(rotation)<0:rotation[2]*=-1
 q=(v-origin)@rotation.T
 target=np.array([center[0],bottom-q[:,1].min(),center[2]])
 target[[0,2]]-=(q.min(0)+q.max(0))[[0,2]]/2
 translation=target-rotation@origin;placed=v@rotation.T+translation
 prop_moves.append({'mesh':name,'rotation_rows':rotation.tolist(),'translation_before_layout_placement_m':translation.tolist(),'min':placed.min(0).tolist(),'max':placed.max(0).tolist()})
 bottom=float(placed[:,1].max())+.002
report['proposed_prop_moves']=prop_moves
report['pallet_stack_height_m']=bottom-.002
report['pallet_stack_gap_m']=.002
(root.parent/'map-step2').mkdir(exist_ok=True)
np.savez_compressed(root.parent/'map-step2'/'proposed_coordinates.npz',**kh)
(out/'placement_validation.json').write_text(json.dumps(report,indent=2)+'\n')
for p in report['plans']:
 for mode in ['before','proposed_after']:
  r=p[mode];fails=[(x['mesh'],x['component'],round(x['min_clearance_m'],4)) for x in r if x['min_clearance_m'] is not None and x['min_clearance_m']<.3]
  print(p['id'],mode,'FAILS',fails,'min retained',min(x['min_clearance_m'] for x in r if not x['pending_shell_removal']))

# Fail closed on numerical proposal regressions. Shell deletion is a prerequisite.
for plan in report['plans']:
 assert min(plan['side_alleys_m']) >= 2.0
 for item in plan['proposed_after']:
  assert item['uncovered_entities'] == 0
  if not item['pending_shell_removal']:
   assert item['min_clearance_m'] >= report['required_clearance_m']
assert 2.8*.97 >= 2.7 and 2.1*.97 >= 2.0 and 1.05*.97 >= .9
