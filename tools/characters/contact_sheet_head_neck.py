"""Compose labeled sheets from captured images, without painting over renders."""
import json,sys
from pathlib import Path
from PIL import Image,ImageDraw
root=Path(sys.argv[1]).resolve()
states=['intact','damaged','fractured_closed','fractured_open','detached'];views=['front','side','back']
def sheet(name,columns,rows,filename):
 image=Image.new('RGB',(len(columns)*320,len(rows)*348),(25,29,34));draw=ImageDraw.Draw(image)
 for y,row in enumerate(rows):
  for x,column in enumerate(columns):
   source=root/filename(column,row)
   render=Image.open(source).convert('RGB');render.thumbnail((320,320))
   image.paste(render,(x*320,y*348+28));draw.text((x*320+5,y*348+6),column+' / '+row,fill='white')
 image.save(root/name)
sheet('blender_contact_sheet.png',states,views,lambda state,view:f'captures_blender/{state}_{view}.png')
poses=['rest']+[x['shape'] for x in json.loads((root/'manifest.json').read_text())['correctives']]
for pose in poses:
 sheet('godot_'+pose+'_contact_sheet.png',states,views,lambda state,view:f'captures_godot/{state}_{pose}_{view}.png')
sheet('godot_interiors_contact_sheet.png',['interiors'],views,lambda state,view:f'captures_godot/{state}_{view}.png')
sheet('godot_variants_contact_sheet.png',['fractured_open_v1','fractured_open_v2','detached_v1','detached_v2'],views,lambda state,view:f'captures_godot/{state}_{view}.png')
print('CONTACT_SHEETS',len(poses)+3)
