"""Independent binary glTF audit of shipped cap geometry and seam attributes."""
import json,struct,sys,math
from pathlib import Path
folder=Path(sys.argv[1]);manifest=json.loads((folder/'manifest.json').read_text());rows=[]
def read_glb(path):
 data=path.read_bytes();length=struct.unpack_from('<I',data,12)[0];doc=json.loads(data[20:20+length]);binary=data[28+length:]
 def accessor(index):
  a=doc['accessors'][index];v=doc['bufferViews'][a['bufferView']];components={'VEC2':2,'VEC3':3,'VEC4':4,'SCALAR':1}[a['type']];fmt={5126:'f',5125:'I',5123:'H',5121:'B'}[a['componentType']];size=struct.calcsize(fmt)*components;off=v.get('byteOffset',0)+a.get('byteOffset',0)
  values=[struct.unpack_from('<'+fmt*components,binary,off+i*v.get('byteStride',size)) for i in range(a['count'])]
  if a.get('normalized'):values=[tuple(x/(65535 if a['componentType']==5123 else 255) for x in row) for row in values]
  return values
 return doc,accessor
for entry in manifest['variants']:
 for lod,name in enumerate(entry['lods']):
  doc,read=read_glb(folder/name);triangles=0;uv_zero=0;bad_range=0;surfaces=0;mirrored_error=0.0
  for mesh in doc['meshes']:
   for primitive in mesh['primitives']:
    surfaces+=1;attrs=primitive['attributes'];pos=read(attrs['POSITION']);uv=read(attrs['TEXCOORD_0']);color=read(attrs['COLOR_0']);indices=[i[0] for i in read(primitive['indices'])]
    triangles+=len(indices)//3
    for start in range(0,len(indices),3):
     a,b,c=[uv[i] for i in indices[start:start+3]]
     if abs((b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0]))<1e-12:uv_zero+=1
    bad_range+=sum(not all(0<=x<=1 for x in item) for item in uv)
    if lod==0:
     center=manifest['source_center_blender'];basis=manifest['source_basis_blender']
     for original in manifest['source_boundary']:
      delta=[original[i]-center[i] for i in range(3)];local=[sum(delta[i]*axis[i] for i in range(3)) for axis in basis];expected=(local[0],local[2],-local[1])
      index=min(range(len(pos)),key=lambda i:sum((pos[i][j]-expected[j])**2 for j in range(3)))
      baseline=(color[index][3]-.5)*.02;mirrored_y=2*baseline-pos[index][1]
      mirrored_error=max(mirrored_error,math.dist((pos[index][0],mirrored_y,pos[index][2]),expected))
  rows.append({'variant':entry['id'],'lod':lod,'triangles':triangles,'surfaces':surfaces,'uv_zero_area_triangles':uv_zero,'uv_out_of_range_vertices':bad_range,'matching_underside_max_error_m':mirrored_error,'file_bytes':(folder/name).stat().st_size})
result={'files':rows,'checks':{'one_surface':all(r['surfaces']==1 for r in rows),'lod0_budget':all(2000<=r['triangles']<=4000 for r in rows if r['lod']==0),'lod1_budget':all(r['triangles']<=800 for r in rows if r['lod']==1),'lod2_single_cap_budget':all(r['triangles']<=320 for r in rows if r['lod']==2),'uv_range':all(r['uv_out_of_range_vertices']==0 for r in rows),'uv_area':all(r['uv_zero_area_triangles']==0 for r in rows),'matching_underside':all(r['matching_underside_max_error_m']<1e-6 for r in rows)}}
(folder/'export_validation.json').write_text(json.dumps(result,indent=2));print(json.dumps(result['checks']))
