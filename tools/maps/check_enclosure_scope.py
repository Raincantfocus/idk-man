"""Compare exported map against prior GLB: script BEFORE_GLB AFTER_GLB REPORT_JSON."""
from pathlib import Path
import sys,json,struct,hashlib,numpy as np
def load(path):
 raw=Path(path).read_bytes();n=struct.unpack_from('<I',raw,12)[0];return json.loads(raw[20:20+n]),raw[28+n:]
def accessor(d,b,i):
 a=d['accessors'][i];v=d['bufferViews'][a['bufferView']];size={5120:1,5121:1,5122:2,5123:2,5125:4,5126:4}[a['componentType']]*{'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}[a['type']];start=v.get('byteOffset',0)+a.get('byteOffset',0);stride=v.get('byteStride',size)
 return b''.join(b[start+j*stride:start+j*stride+size] for j in range(a['count']))
def fingerprint(d,b,node):
 result=[]
 for p in d['meshes'][node['mesh']]['primitives']:
  result.append({k:hashlib.sha256(accessor(d,b,i)).hexdigest() for k,i in p['attributes'].items()});result[-1]['indices']=hashlib.sha256(accessor(d,b,p['indices'])).hexdigest()
 return result
def geometry(d,b,node):
 p=d['meshes'][node['mesh']]['primitives'][0]
 v=np.frombuffer(accessor(d,b,p['attributes']['POSITION']),dtype='<f4').reshape(-1,3)
 dtype={5121:'u1',5123:'<u2',5125:'<u4'}[d['accessors'][p['indices']]['componentType']]
 indices=np.frombuffer(accessor(d,b,p['indices']),dtype=dtype).reshape(-1,3)
 # Compare position triangles independent of export vertex/index ordering.
 triangles=[]
 for tri in np.round(v[indices],5):triangles.append(tuple(sorted(tuple(row) for row in tri)))
 return sorted(triangles)
a,ab=load(sys.argv[1]);b,bb=load(sys.argv[2]);checks={}
for node in a['nodes']:
 if 'mesh' not in node:continue
 if node['name'].startswith('NurbsPath'):
  target=next(n for n in b['nodes'] if n.get('name')==node['name']);checks[node['name']+'_attributes_and_indices']=fingerprint(a,ab,node)==fingerprint(b,bb,target)
 if node['name']=='Staging_TimberPlatforms':
  target=next(n for n in b['nodes'] if n.get('name')==node['name']);checks['platform_position_triangles_at_10_micrometre_precision']=geometry(a,ab,node)==geometry(b,bb,target)
  checks['platform_transform_unchanged']=all(node.get(k)==target.get(k) for k in ['translation','rotation','scale','matrix'])
checks['existing_material_definitions_unchanged']=a['materials']==b['materials']
Path(sys.argv[3]).write_text(json.dumps(checks,indent=2)+'\n');print(checks);assert all(checks.values())
