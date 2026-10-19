"""Shared 128px pool atlas used by Decal and the Compatibility surface fallback."""
from PIL import Image
from pathlib import Path
import math,sys
out=Path(sys.argv[1]);n=128
for name in ['pool_albedo','pool_normal','pool_wet_orm','pool_dry_orm']:
 im=Image.new('RGBA',(n,n));px=im.load()
 for y in range(n):
  for x in range(n):
   u=(x+.5)/n*2-1;v=(y+.5)/n*2-1;angle=math.atan2(v,u);radius=math.hypot(u,v);rim=.83+.045*math.sin(angle*7)+.025*math.sin(angle*13)
   alpha=round(max(0,min(1,(rim-radius)*30))*225)
   if name=='pool_albedo':c=(49,7,12,alpha)
   elif name=='pool_normal':c=(128,128,255,255)
   else:c=(255,36 if name=='pool_wet_orm' else 165,0,255)
   px[x,y]=c
 im.save(out/(name+'.png'))
