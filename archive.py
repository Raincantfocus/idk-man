import os,tarfile,json,hashlib,pathlib
root=pathlib.Path('/workspace');out=pathlib.Path('/tmp/zero-line-environment'); inventory=[]; excluded=[]
skipdirs={'.git','.godot','__pycache__','node_modules','.ssh','.aws','.azure','.config','.cache','blender5-env','venv','.venv'}
def allowed(p):
 n=p.name.lower()
 return not (n=='.env' or n.startswith('.env.') or n in {'credentials','credentials.json','id_rsa','id_ed25519'} or n.endswith(('.pem','.key','.pyc')) or 'token'==n or n=='.git-credentials')
for base,dirs,files in os.walk(root):
 dirs[:]=[d for d in dirs if d not in skipdirs]
 for n in files:
  p=pathlib.Path(base)/n
  if p.is_symlink() or not allowed(p):excluded.append(str(p.relative_to(root)));continue
  if p.is_file():inventory.append({'path':str(p.relative_to(root)),'bytes':p.stat().st_size})
(out/'inventory.json').write_text(json.dumps({'root':'/workspace','files':inventory,'excluded_files':excluded,'excluded_directory_names':sorted(skipdirs)},indent=2))
print('FILES',len(inventory),'BYTES',sum(r['bytes'] for r in inventory),flush=True)
# Stream one compressed tar into independently bounded GitHub-sized chunks.
class Chunks:
 def __init__(self):self.i=0;self.f=None;self.used=0
 def write(self,b):
  total=len(b)
  while b:
   if self.f is None:self.f=open(out/f'workspace.tar.gz.part{self.i:04d}','wb');self.i+=1;self.used=0
   k=min(len(b),80*1024*1024-self.used);self.f.write(b[:k]);self.used+=k;b=b[k:]
   if self.used==80*1024*1024:self.f.close();self.f=None;print('CHUNK',self.i,flush=True)
  return total
 def flush(self):
  if self.f:self.f.flush()
c=Chunks()
with tarfile.open(fileobj=c,mode='w|gz',compresslevel=1) as tar:
 for r in inventory:
  try:tar.add(root/r['path'],arcname=r['path'],recursive=False)
  except FileNotFoundError:pass
if c.f:c.f.close()
with open(out/'SHA256SUMS','w') as f:
 for p in sorted(out.glob('workspace.tar.gz.part*')):
  h=hashlib.sha256()
  with p.open('rb') as src:
   for b in iter(lambda:src.read(1024*1024),b''):h.update(b)
  f.write(h.hexdigest()+'  '+p.name+'\n')
print('DONE',flush=True)
