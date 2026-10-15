"""Deterministic original 2K tileable surface maps; linear ORM and OpenGL normals."""
from pathlib import Path
import numpy as np
from PIL import Image
import hashlib,json
root=Path(__file__).resolve().parents[1]/'assets/surfaces';root.mkdir(exist_ok=True)
n=2048;rng=np.random.default_rng(741);y,x=np.mgrid[:n,:n]/n
noise=rng.random((n,n)).astype('float32')
broad=(np.sin(x*25.1327+np.sin(y*18.8496))+np.cos(y*31.4159))/4+.5
sets={'steel':([.22,.24,.25],.48,.88),'cloth':([.38,.40,.33],.9,0),'skin':([.70,.48,.36],.66,0),'tissue':([.29,.055,.045],.25,0),'concrete':([.40,.41,.38],.93,0)}
for name,(rgb,rough,metal) in sets.items():
 detail=noise*.06
 if name=='cloth': detail+=.07*np.sin(x*n*1.57)*np.sin(y*n*1.57)
 if name=='steel': detail+=.10*((noise>.998)&(np.sin(y*600)>0))
 height=detail+broad*.035
 color=np.clip(np.array(rgb)[None,None,:]*(.77+broad[...,None]*.28+detail[...,None]),0,1)
 dy,dx=np.gradient(height);normal=np.stack([-dx*2,-dy*2,np.ones_like(dx)],-1);normal/=np.linalg.norm(normal,axis=-1,keepdims=True)
 orm=np.stack([np.clip(.91+detail,0,1),np.clip(rough+(broad-.5)*.15+detail,0,1),np.full_like(x,metal)],-1)
 for suffix,a in [('albedo',color),('normal',normal*.5+.5),('orm',orm)]:Image.fromarray((a*255).astype('uint8')).save(root/f'{name}_{suffix}.png')
manifest={'origin':'Original procedural surface art, not scanned anatomy','resolution':2048,'orm_channels':'R ambient occlusion, G roughness, B metallic','source':'tools/author_surface_maps.py','files':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(root.glob('*.png'))}}
(root/'provenance.json').write_text(json.dumps(manifest,indent=2)+'\n')
