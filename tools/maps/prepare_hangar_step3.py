"""Prepare approved Option A geometry and reconciled staging data.
Usage: script INTAKE STEP2_REPORT STEP2_ARRAYS OUTPUT
"""
import json,sys,math
from pathlib import Path
import numpy as np
from scipy.sparse import coo_matrix
from scipy.sparse.csgraph import connected_components
root,rp,ap,out=map(Path,sys.argv[1:]);out.mkdir(parents=True,exist_ok=True)
r=json.loads(rp.read_text());data=np.load(ap);data={k:data[k].copy() for k in data.files};source=np.load(root/'killhouse.npz')
rows=json.loads((root/'killhouse.json').read_text());row=next(x for x in rows if x['name']=='Object_16');v=source[row['key']+'_v'];f=source[row['key']+'_f']
u,inv=np.unique(np.round(v,5),axis=0,return_inverse=True);fi=inv[f];e=np.concatenate([fi[:,[0,1]],fi[:,[1,2]],fi[:,[2,0]]]);_,labels=connected_components(coo_matrix((np.ones(len(e)),(e[:,0],e[:,1])),shape=(len(u),len(u))),directed=False);comps=labels[inv][f[:,0]]
v=data['Object_16_v'];vi=np.unique(f[np.isin(comps,list(range(49,70))) ]);sel=vi[v[vi,1]>3];v[sel,1]=3+(v[sel,1]-3)*.55
for move in r['proposed_prop_moves']:
 name=move['mesh'];data[name+'_v']=data[name+'_v']@np.array(move['rotation_rows']).T+move['translation_before_layout_placement_m']
for key in data:
 if key.endswith('_v'):data[key]+=[8,0,-23.07500648498535]
t=data['Object_16_v'][f];normal=np.cross(t[:,1]-t[:,0],t[:,2]-t[:,0]);area=np.linalg.norm(normal,axis=1)/2
ceiling=np.isin(comps,[19,48,72])&(t[:,:,1].min(1)>2.5)&(np.abs(normal[:,1])>np.linalg.norm(normal,axis=1)*.5)&(area>.2)
data['Object_16_remove_faces']=np.flatnonzero((comps==0)|ceiling)
np.savez_compressed(out/'prepared.npz',**data)
# Native warehouse geometry headroom probe, including Metal and Emissive.
w=np.load(root/'warehouse.npz');tri=np.concatenate([w['mesh0_v'][w['mesh0_f']],w['mesh1_v'][w['mesh1_f']]])
def overhead(xs,zs):
 pts=np.array([(x,z) for x in xs for z in zs]);height=np.full(len(pts),np.inf)
 for t in tri:
  a,b,c=t[:,[0,2]];d=(b-a)[0]*(c-a)[1]-(b-a)[1]*(c-a)[0]
  if abs(d)<1e-10 or t[:,1].max()<2.5:continue
  near=(pts[:,0]>=min(t[:,0])-1e-8)&(pts[:,0]<=max(t[:,0])+1e-8)&(pts[:,1]>=min(t[:,2])-1e-8)&(pts[:,1]<=max(t[:,2])+1e-8)
  ids=np.flatnonzero(near);q=pts[ids]-a
  u=(q[:,0]*(c-a)[1]-q[:,1]*(c-a)[0])/d;v=((b-a)[0]*q[:,1]-(b-a)[1]*q[:,0])/d
  ok=(u>=-1e-8)&(v>=-1e-8)&(u+v<=1+1e-8);ids=ids[ok];y=t[0,1]+u[ok]*(t[1,1]-t[0,1])+v[ok]*(t[2,1]-t[0,1]);height[ids]=np.minimum(height[ids],y)
 i=np.argmin(height);return {'minimum_overhead_y_m':float(height[i]),'critical_xz':pts[i].tolist(),'samples':len(pts),'missing':int(np.isinf(height).sum())}
platforms=[]
for name,z0,z1,landing,direction in [('north',-8.8,-2,-8.8,-1),('south',-45,-38.2,-38.2,1)]:
 probe=overhead(np.linspace(2.25,5.5,66),np.linspace(z0,z1,137));deck=1.8;run=deck/math.tan(math.radians(32));platforms.append({'id':name,'x_bounds':[2.25,5.5],'z_bounds':[z0,z1],'deck_y_m':deck,'deck_thickness_m':.16,'stairs_width_m':1.2,'stairs_top':[3.75,deck,landing],'stairs_base':[3.75,0,landing+direction*run],'stairs_angle_degrees':32,'stairs_run_m':run,'roof_probe':probe,'standing_capsule_height_m':1.72,'sampled_head_gap_m':probe['minimum_overhead_y_m']-deck-1.72,'status':'layout_ready_asset_build_pending'})
config={'status':'Step 3 shell integrated; staging assets planned, not yet spawned','approved_plan':'A','warehouse_floor_z_bounds':[-46.150013,0],'layout_translation_m':[8,0,-23.07500648498535],'layout_scale':2.91,'platforms':platforms,'egress':[{'id':'north','position':[8,0,-12],'width':1.2,'height':2.2,'depth':1.6},{'id':'south','position':[8,0,-34.5],'width':1.2,'height':2.2,'depth':1.6}], 'staging_props':[
{'id':'WoodenBarricade','position':[8,0,-4],'size':[2,1.3,.2],'status':'author_mesh'},
{'id':'IndustrialCrates','position':[11.5,0,-3.5],'size':[1.2,1.4,1.2],'status':'source_mesh_review'},
{'id':'SedanWreck','position':[8.2,0,-7.5],'yaw_degrees':30,'status':'duplicate_supplied_car_later','length_m':4},
{'id':'StorageContainer','x_bounds':[11.75,13.75],'z_bounds':[-10,-6],'height':2.6,'status':'author_mesh'},
{'id':'PalletAndBench','position':[10,0,-10.5],'status':'pallet_available_bench_asset_missing'},
{'id':'ConcreteBarrier','position':[8.5,0,-36.4],'size':[2.4,1.1,.6],'yaw_degrees':-5,'status':'author_mesh'},
{'id':'Forklift','position':[12,0,-37.5],'size':[2.4,2.1,1.2],'yaw_degrees':90,'status':'asset_missing'},
{'id':'TruckWreck','position':[8.3,0,-39.5],'size':[5.2,1.9,2.1],'yaw_degrees':-45,'status':'asset_missing_source_box_not_verified_as_truck'},
{'id':'CargoContainer','x_bounds':[11.75,13.75],'z_bounds':[-44.5,-39.5],'height':2.6,'status':'author_mesh'},
{'id':'CouchAndCrates','position':[8.5,0,-43],'status':'couch_asset_missing'}], 'removed_source_shell_faces':int((comps==0).sum()),'removed_room_ceiling_faces':int(ceiling.sum())}
(out/'staging_layout.json').write_text(json.dumps(config,indent=2)+'\n')
print(json.dumps(platforms,indent=2));print('ceiling triangles',ceiling.sum())
