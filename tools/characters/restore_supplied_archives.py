"""Recover the four supplied single-entry split ZIPs, verifying CRC and known SHA256.
Usage: python tools/characters/restore_supplied_archives.py ATTACHMENTS PRIVATE_OUTPUT
Never writes source assets into the checkout. No attached scripts are executed.
"""
from pathlib import Path
import hashlib,json,struct,sys,zlib
src=Path(sys.argv[1]).resolve();dst=Path(sys.argv[2]).resolve()
repo=Path(__file__).resolve().parents[2]
assert not dst.is_relative_to(repo), 'Purchased assets must remain in private staging'
dst.mkdir(parents=True,exist_ok=True)
expected={
'GROM':(5,'719e6e0363cec5974856dc528e5c50035dd89232b50a823b04d6305f656b985e'),
'Konig':(10,'92908516017e79d58237810bbcc5836eed808e2ea8b3525fab4f818ff5864151'),
'Soup_masked':(15,'8d48cfa3045986c8f62f9447d2224f9f97530e9f98c86d1e76136927c5fd2165'),
'Makarov (shaded soldier)':(15,'c924ab384fd7d36fc696b1883584a3d3a8fbce3fbafa149652ca4a75ace0f119')}
results=[]
for name,(n,expected_sha) in expected.items():
 paths=[]
 for suffix in [f'.z{i:02}' for i in range(1,n+1)]+['.zip']:
  found=list(src.glob('*/'+name+suffix));assert len(found)==1,(name,suffix,found)
  paths.append(found[0])
 tail=paths[-1].read_bytes();idx=tail.rfind(b'PK\x01\x02');assert idx>=0
 h=struct.unpack_from('<4s6H3I5H2I',tail,idx)
 filename=tail[idx+46:idx+46+h[10]].decode();assert filename==name+'.blend'
 crc,compressed,size=h[7:10]
 if size==0xffffffff:
  extra=tail[idx+46+h[10]:idx+46+h[10]+h[11]];assert extra[:4]==b'\x01\x00\x08\x00'
  size=struct.unpack_from('<Q',extra,4)[0]
 assert 0<size<4*1024**3 and h[4]==8 and h[3]==0
 with paths[0].open('rb') as f:head=f.read(4096)
 assert head[4:8]==b'PK\x03\x04';local=struct.unpack_from('<4s5H3I2H',head,4)
 offset=34+local[-2]+local[-1]
 out=dst/name/'extracted'/filename;out.parent.mkdir(parents=True,exist_ok=True)
 staging=out.with_suffix('.partial');remaining=compressed;total=0;actual_crc=0;sha=hashlib.sha256();d=zlib.decompressobj(-15)
 with staging.open('wb') as writer:
  for index,path in enumerate(paths):
   with path.open('rb') as reader:
    if index==0:reader.seek(offset)
    while remaining:
     chunk=reader.read(min(65536,remaining))
     if not chunk:break
     remaining-=len(chunk);data=d.decompress(chunk);total+=len(data);assert total<=size
     writer.write(data);sha.update(data);actual_crc=zlib.crc32(data,actual_crc)
 assert not remaining and d.eof and total==size and actual_crc==crc,(name,'CRC/size failure')
 assert sha.hexdigest()==expected_sha,(name,'SHA256 mismatch')
 staging.replace(out)
 results.append(dict(name=name,parts=len(paths),bytes=total,crc32=f'{crc:08x}',sha256=sha.hexdigest(),path=str(out)))
 print('VERIFIED',name,total,'bytes',flush=True)
(dst/'archive-validation.json').write_text(json.dumps(results,indent=2)+'\n')
