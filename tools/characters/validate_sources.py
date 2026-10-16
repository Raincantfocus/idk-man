"""Offline source integrity and exported glTF skin/geometry checks."""
import hashlib, json, struct
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
manifest=json.loads((ROOT/'assets/characters/provenance.json').read_text())
for asset in manifest['assets']:
 path=ROOT/asset['path']
 assert path.is_file(),path
 assert hashlib.sha256(path.read_bytes()).hexdigest()==asset['sha256'],f'Hash mismatch: {path}'
 if not asset['path'].endswith('.md'):assert asset['license']=='CC0-1.0'

def read_glb(path):
 raw=path.read_bytes();length=struct.unpack_from('<I',raw,12)[0]
 data=json.loads(raw[20:20+length]);start=20+length
 assert struct.unpack_from('<I',raw,start+4)[0]==0x004e4942
 return data,raw[start+8:]

def values(data,blob,index):
 a=data['accessors'][index];view=data['bufferViews'][a['bufferView']]
 code,size={5126:('f',4),5123:('H',2),5121:('B',1),5125:('I',4)}[a['componentType']]
 width={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}[a['type']]
 start=view.get('byteOffset',0)+a.get('byteOffset',0);stride=view.get('byteStride',size*width)
 return [struct.unpack_from('<'+code*width,blob,start+i*stride) for i in range(a['count'])]
report=[]
for path in sorted((ROOT/'assets/characters/generated').glob('*.glb')):
 data,blob=read_glb(path)
 assert len(data['skins'])==1 and len(data['skins'][0]['joints'])==72,path
 assert not data.get('animations'),f'Unexpected generated animation: {path}'
 names={data['nodes'][i]['name'] for i in data['skins'][0]['joints']}
 assert len(names)==72
 assert all(side+part in names for side in ['Left','Right'] for part in ['UpperArmTwist','LowerArmTwist','UpperLegTwist','LowerLegTwist'])
 triangles=0;vertices=0;blended=0
 for mesh in data['meshes']:
  for primitive in mesh['primitives']:
   attributes=primitive['attributes'];assert all(k in attributes for k in ['POSITION','NORMAL','TEXCOORD_0','JOINTS_0','WEIGHTS_0'])
   weights=values(data,blob,attributes['WEIGHTS_0']);joints=values(data,blob,attributes['JOINTS_0'])
   for ws,js in zip(weights,joints):
    assert abs(sum(ws)-1)<1e-4 and min(ws)>=0
    assert all(j<72 for j,w in zip(js,ws) if w>0)
    blended+=sum(w>1e-4 for w in ws)>1;vertices+=1
   triangles+=data['accessors'][primitive['indices']]['count']//3
 assert len(data.get('materials',[]))==1,path
 report.append({'file':path.name,'triangles':triangles,'bones':72,'materials':1,'blended_vertices_percent':round(100*blended/vertices,2)})
assert len(report)==20
output=ROOT/'data/characters/validation.json'
output.write_text(json.dumps({'source_hashes_verified':len(manifest['assets']),'exports':report,'production_ready':False},indent=2)+'\n')
print('SOURCE VALIDATION:',len(manifest['assets']),'hashes; 20 GLBs; normalized skin weights; 72 joints; UVs/normals; no animation')
print('Standard LOD0:',next(r for r in report if r['file']=='standard_lod0.glb'))
