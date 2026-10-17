"""Validate and privately extract supplied motion ZIPs, including the four-volume FPS ZIP."""
from pathlib import Path,PurePosixPath
import sys,zipfile,struct,zlib,hashlib,json
src=Path(sys.argv[1]);out=Path(sys.argv[2]).resolve();repo=Path(__file__).resolve().parents[2]
assert not out.is_relative_to(repo)
out.mkdir(parents=True,exist_ok=True);report=[]
def safe_path(root,name):
 p=PurePosixPath(name);assert not p.is_absolute() and '..' not in p.parts and '\\' not in name and ':' not in name,name
 return root.joinpath(*p.parts)
for path in src.glob('*/*.zip'):
 if not (path.name.startswith('Actorcore-') or path.name in ['MotionLibrary_Weapons.zip','animated fps rifle hands.zip']):continue
 root=out/path.stem;root.mkdir(exist_ok=True);entries=[]
 if path.name=='animated fps rifle hands.zip':
  paths=[next(src.glob('*/animated fps rifle hands.z%02d'%i)) for i in range(1,4)]+[path]
  chunks=[p.read_bytes() for p in paths];offsets=[0]
  for c in chunks[:-1]:offsets.append(offsets[-1]+len(c))
  blob=b''.join(chunks);tail=chunks[-1];e=tail.rfind(b'PK\x05\x06');end=struct.unpack_from('<4s4H2IH',tail,e)
  assert end[1]==3 and end[2]==3 and end[3]==end[4]
  central=end[6]
  for index in range(end[4]):
   h=struct.unpack_from('<4s6H3I5H2I',tail,central);assert h[0]==b'PK\x01\x02'
   name=tail[central+46:central+46+h[10]].decode('utf8');central+=46+h[10]+h[11]+h[12]
   assert h[3]&1==0 and h[4] in [0,8] and h[9]<512*1024**2
   assert (h[15]>>16)&0o170000!=0o120000
   target=safe_path(root,name)
   if name.endswith('/'):target.mkdir(parents=True,exist_ok=True);continue
   start=offsets[h[13]]+h[16];local=struct.unpack_from('<4s5H3I2H',blob,start);assert local[0]==b'PK\x03\x04'
   start+=30+local[-2]+local[-1];packed=blob[start:start+h[8]];data=zlib.decompress(packed,-15) if h[4]==8 else packed
   assert len(data)==h[9] and zlib.crc32(data)==h[7]
   target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(data)
   entries.append(dict(path=str(target.relative_to(out)),bytes=len(data),sha256=hashlib.sha256(data).hexdigest()))
 else:
  with zipfile.ZipFile(path) as z:
   assert sum(i.file_size for i in z.infolist())<512*1024**2
   for info in z.infolist():
    assert (info.external_attr>>16)&0o170000!=0o120000
    target=safe_path(root,info.filename)
    if info.is_dir():target.mkdir(parents=True,exist_ok=True);continue
    data=z.read(info) # zipfile checks CRC on full reads.
    target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(data)
    entries.append(dict(path=str(target.relative_to(out)),bytes=len(data),sha256=hashlib.sha256(data).hexdigest()))
 report.append(dict(archive=path.name,crc_verified=True,entries=entries));print('VERIFIED',path.name,len(entries),'files',flush=True)
assert len(report)==8
(out/'archive_manifest.json').write_text(json.dumps(report,indent=2)+'\n')
