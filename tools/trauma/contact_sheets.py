from PIL import Image,ImageDraw
from pathlib import Path
import sys,json
root=Path(sys.argv[1]);cap=root/'captures';dest=root/'sheets';dest.mkdir(exist_ok=True)
groups={}
for lighting in ['neutral','arena']:
 for distance in ['0.5','2.0','8.0']:groups[lighting+'_'+distance+'m']=[cap/f'v{i:02d}_{lighting}_{distance}m.png' for i in range(12)]
groups['orthographic_side']=[cap/f'v{i:02d}_ortho_side.png' for i in range(12)]
groups['matching_undersides']=[cap/f'v{i:02d}_matching_underside.png' for i in range(12)]
groups['effects']=[cap/x for x in ['arterial_pulse_full.png','shotgun_head_pop.png','blood_pool_four_seconds.png','rifle_lod1.png','rifle_lod2.png']]
for name,paths in groups.items():
 width=384;height=410;columns=3;rows=(len(paths)+columns-1)//columns
 sheet=Image.new('RGB',(columns*width,rows*height),(20,23,26));draw=ImageDraw.Draw(sheet)
 for i,path in enumerate(paths):
  if not path.exists():raise RuntimeError('Missing capture '+str(path))
  im=Image.open(path).convert('RGB');im.thumbnail((width,384))
  x=(i%columns)*width;y=(i//columns)*height;sheet.paste(im,(x,y+24));draw.text((x+6,y+5),path.stem,fill='white')
 sheet.save(dest/(name+'.jpg'),quality=92)
print('CONTACT_SHEETS',len(groups))
