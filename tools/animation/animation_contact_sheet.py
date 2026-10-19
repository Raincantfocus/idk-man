from PIL import Image,ImageDraw
from pathlib import Path
import sys
root=Path(sys.argv[1]);names=['hold','run_start','run_loop','run_stop','fire','reload_cover','turn_left','turn_right','side_shoot']
sheet=Image.new('RGB',(1200,1170),(25,27,30));draw=ImageDraw.Draw(sheet)
for i,name in enumerate(names):
 im=Image.open(root/'captures'/(name+'_50.png')).convert('RGB').resize((400,360));x=(i%3)*400;y=(i//3)*390;sheet.paste(im,(x,y));draw.text((x+8,y+365),name+' | native mid-clip capture',fill='white')
sheet.save(root/'animation_contact_sheet.jpg',quality=92)
