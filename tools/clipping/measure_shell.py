"""Blender 4.3.2 BVH audit of Godot-exported skinning, without changing assets.
blender -b -P tools/clipping/measure_shell.py -- INPUT_JSON OUTPUT_DIR [PATCH_JSON]
"""
import bpy,json,sys,time,math
import numpy as np
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
from mathutils.kdtree import KDTree
args=sys.argv[sys.argv.index('--')+1:];data=json.loads(Path(args[0]).read_text());out=Path(args[1]);out.mkdir(parents=True,exist_ok=True)
patch=json.loads(Path(args[2]).read_text()) if len(args)>2 else {'meshes':{}}
regions=['neck_collar','chest','abdomen','shoulders','elbows','wrists','hips','knees','ankles']
def transforms(rows):
 a=np.array(rows,dtype=np.float64).reshape(-1,3,4);m=np.zeros((len(a),4,4));m[:,:3,:]=a;m[:,3,3]=1;return m
rests=transforms(data['rests']);meshes=[]
for raw in data['meshes']:
 m={'name':raw['name'],'v':np.array(raw['vertices'],dtype=np.float64),'n':np.array(raw['normals'],dtype=np.float64),'f':np.array(raw['indices'],dtype=np.int32).reshape(-1,3),'w':np.array(raw['weights']).reshape(len(raw['vertices']),-1),'j':np.array(raw['joints'],dtype=int).reshape(len(raw['vertices']),-1),'bind':transforms(raw['binds']),'map':np.array(raw['bind_bones'],dtype=int)}
 change=patch['meshes'].get(m['name'],{})
 for key in ['v','w','j']:
  if key in change:m[key]=np.array(change[key],dtype=int if key=='j' else float)
 m["correctives"]={k:np.array(v) for k,v in change.get("correctives",{}).items()}
 meshes.append(m)
def skin(m,pose):
 mats=pose[m['map']]@m['bind'];vertices=m['v'].copy()
 for rule in patch.get('corrective_rules',[]):
  bone=data['bones'].index(rule['bone']);parent=patch['bone_parents'][bone]
  local=np.linalg.inv(pose[parent])@pose[bone] if parent>=0 else pose[bone]
  rest_local=np.linalg.inv(rests[parent])@rests[bone] if parent>=0 else rests[bone]
  rotation=(np.linalg.inv(rest_local)@local)[:3,:3]
  angle=abs(math.atan2(rotation[0,2],rotation[2,2])) if rule['axis']=='yaw' else math.acos(float(np.clip((np.trace(rotation)-1)/2,-1,1)))
  t=float(np.clip((math.degrees(angle)-rule['start_degrees'])/(rule['full_degrees']-rule['start_degrees']),0,1));t=t*t*(3-2*t)
  vertices+=m['correctives'][rule['name']]*t
 p=np.c_[vertices,np.ones(len(vertices))];v=np.zeros((len(p),3));n=np.zeros_like(v)
 for slot in range(m['j'].shape[1]):
  selected=mats[m['j'][:,slot]];w=m['w'][:,slot,None]
  v+=np.einsum('nij,nj->ni',selected[:,:3,:],p)*w
  n+=np.einsum('nij,nj->ni',selected[:,:3,:3],m['n'])*w
 n/=np.maximum(np.linalg.norm(n,axis=1)[:,None],1e-10)
 return v,n
body=meshes[0];rest_v,rest_n=skin(body,rests);kd=KDTree(len(rest_v))
for i,p in enumerate(rest_v):kd.insert(Vector(p),i)
kd.balance()
# Region semantics use actual skin weights and the nearest anatomical joint.
labels=[]
for i,p in enumerate(rest_v):
 bone=data['bones'][body['map'][body['j'][i,np.argmax(body['w'][i])]]]
 prefix='Left' if 'Left' in bone else 'Right'
 def distance(name):return np.linalg.norm(p-rests[data['bones'].index(name),:3,3]) if name in data['bones'] else 1
 if any(x in bone for x in ['Eye','Jaw','Head']):label='excluded'
 elif 'Neck' in bone:label='neck_collar'
 elif any(x in bone for x in ['Hand','Thumb','Index','Middle','Ring','Little']):label='wrists'
 elif 'LowerArm' in bone:label='elbows' if distance(prefix+'LowerArm')<.13 else 'wrists'
 elif 'UpperArm' in bone or 'Shoulder' in bone:label='elbows' if distance(prefix+'LowerArm')<.10 else 'shoulders'
 elif 'UpperLeg' in bone:label='knees' if distance(prefix+'LowerLeg')<.13 else 'hips'
 elif 'LowerLeg' in bone:label='knees' if distance(prefix+'LowerLeg')<.14 else 'ankles'
 elif 'Foot' in bone or 'Toes' in bone:label='ankles'
 elif bone in ['Hips','Root']:label='hips'
 elif bone=='Spine':label='abdomen'
 else:label='chest'
 labels.append(label)
# Count unique body points, not duplicated UV seam vertices.
unique={}
for i,p in enumerate(rest_v):
 if labels[i]!='excluded':unique.setdefault(tuple(np.round(p,6)),i)
ids=np.array(list(unique.values()),dtype=int)
raw_covered_count=len(ids)
mask=patch['meshes'].get(body['name'],{}).get('covered')
if len(args)>3 and args[3]=='raw':mask=None
if mask is not None:ids=np.array([i for i in ids if not mask[i]],dtype=int)
all_heat=np.zeros(len(rest_v));worst=None;worst_depth=-1
gear_faces=[];offset=0;flip_count=0
for m in meshes[1:]:
 v,n=skin(m,rests);faces=m['f'].copy()
 for f in faces:
  a,b,c=v[f];normal=np.cross(b-a,c-a);_,near,_=kd.find(Vector((a+b+c)/3))
  if np.dot(normal,rest_n[near])<0:f[1],f[2]=f[2],f[1];flip_count+=1
 gear_faces.extend((faces+offset).tolist());offset+=len(v)
rows=[];frame_rows=[];started=time.monotonic()
for clip in data['clips']:
 aggregate={r:{'tested_vertices':sum(labels[i]==r for i in ids),'outside_vertices':set(),'over_2mm_vertices':set(),'uncovered_vertices':set(),'max_penetration_mm':0.0,'worst_frame':0,'samples':len(clip['samples'])} for r in regions}
 for sample in clip['samples']:
  pose=transforms(sample['bones']);v,n=skin(body,pose);gear=np.concatenate([skin(m,pose)[0] for m in meshes[1:]],axis=0)
  bvh=BVHTree.FromPolygons(gear.tolist(),gear_faces,all_triangles=True)
  frame_max=0;outside_count=0;uncovered_count=0;heat=np.zeros(len(v))
  for i in ids:
   p=Vector(v[i]);normal=Vector(n[i]);q,face_n,index,distance=bvh.find_nearest(p,.12);a=aggregate[labels[i]]
   if q is None:a['uncovered_vertices'].add(int(i));uncovered_count+=1;heat[i]=.12;continue
   signed=(p-q).dot(face_n)
   if signed<=0:continue
   # A second clothing layer may cover the nearest (inner) shell. Outward-facing
   # first ray hit proves local layered coverage; no camera-specific occlusion.
   hit,hn,hi,hd=bvh.ray_cast(p+normal*.00005,normal,.12)
   if hit is not None and hn.dot(normal)>.05:continue
   depth=float(distance);heat[i]=depth;outside_count+=1;a['outside_vertices'].add(int(i))
   if depth>.002:a['over_2mm_vertices'].add(int(i))
   if depth*1000>a['max_penetration_mm']:a['max_penetration_mm']=depth*1000;a['worst_frame']=sample['frame']
   frame_max=max(frame_max,depth)
  all_heat=np.maximum(all_heat,heat)
  if frame_max>worst_depth:worst_depth=frame_max;worst={'clip':clip['name'],'frame':sample['frame'],'time':sample['time'],'heat_m':heat.tolist()}
  frame_rows.append({'clip':clip['name'],'frame':sample['frame'],'time':sample['time'],'outside_vertices':outside_count,'uncovered_vertices':uncovered_count,'max_penetration_mm':frame_max*1000})
 for region,a in aggregate.items():
  for key in ['outside_vertices','over_2mm_vertices','uncovered_vertices']:a[key]=len(a[key])
  rows.append(dict(clip=clip['name'],region=region,role=data['role'],body=data['body'],**a))
 print('CLIP_MEASURED',clip['name'],round(time.monotonic()-started,1),'s',flush=True)
result={'method':'nearest oriented BVH shell, outward-normal ray for outer-layer coverage; 120 mm search radius; duplicated rest positions counted once','engine_source':data['engine'],'samples':len(frame_rows),'body_unique_covered_vertices':raw_covered_count,'visible_vertices_tested':len(ids),'mask_applied':mask is not None,'orientation_corrections':flip_count,'rows':rows,'frames':frame_rows,'pass_margin_mm':2,'passes_available_fixture':all(r['max_penetration_mm']<=2 and r['uncovered_vertices']==0 for r in rows),'full_acceptance':False,'limitations':['Open garment boundaries can produce uncertain signed-distance classification; uncovered searches fail acceptance','Vertex samples do not certify zero visible raster fragments or triangle-only intersections','Only standard body and current Enforcer-like review kit exist in this fixture','Flinch and death clips not available in the current AnimationLibrary'],'elapsed_seconds':time.monotonic()-started}
(out/'measurement.json').write_text(json.dumps(result,indent=2));(out/'heat.json').write_text(json.dumps({'labels':labels,'max_heat_m':all_heat.tolist(),'worst':worst}));print('MEASUREMENT_COMPLETE',result['passes_available_fixture'],flush=True)
