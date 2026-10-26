"""Deterministic authored mathematical wound texture set; OpenGL +Y normals.
No external images. Outputs a reusable RGBA/normal/ORM/height set, 512².
"""
from pathlib import Path
import numpy as np
from PIL import Image
out=Path(__file__).resolve().parents[2]/'assets/wounds';out.mkdir(exist_ok=True)
n=512
v,u=np.mgrid[0:n,0:n]/(n-1);x=(u-.5)*2;y=(v-.5)*2
r=np.sqrt(x*x+y*y);a=np.arctan2(y,x)
rng=np.random.default_rng(7319);noise=rng.random((n,n))
edge=.73+.045*np.sin(a*7)+.025*np.sin(a*19+1)+.018*np.sin(a*37)
t=r/edge
alpha=np.clip((1-t)*18,0,1)
fibers=.5+.5*np.sin(a*43+r*71+noise*2)
depth=np.clip(1-(t/.77)**2,0,1)*(.82+.12*fibers)
# Recessed core, uneven raised wet rim. Height is surface elevation (white high).
height=np.clip(.72-depth*.65+.12*np.exp(-((t-.68)/.1)**2),0,1)
core=np.clip(t/.63,0,1)**1.8
rgb=np.stack([.035+.23*core,.009+.018*core,.012+.016*core],axis=-1)
rgb*=((.78+.22*noise)*(.84+.16*fibers))[...,None]
rgba=np.dstack([rgb,alpha])
rough=np.clip(.18+.20*(1-core)+noise*.045,.1,.6)
ao=.28+.72*(1-depth)
orm=np.dstack([ao,rough,np.zeros_like(r)])
dy,dx=np.gradient(height);normal=np.dstack([-dx*14,dy*14,np.ones_like(r)])
normal/=np.linalg.norm(normal,axis=-1,keepdims=True)
for name,data in [('albedo',rgba),('normal',normal*.5+.5),('orm',orm),('height',height)]:
 Image.fromarray((np.clip(data,0,1)*255).astype('uint8')).save(out/(name+'.png'))
