from PIL import Image,ImageDraw
from pathlib import Path
import sys
root=Path(sys.argv[1]);(root/'sheets').mkdir(exist_ok=True)
for label,indices,pattern,columns,size in [('all_variants',range(45),'neutral_0.5m',9,288),('families_arena',[0,12,15,27,30,33,36,39,42],'arena_0.5m',3,384),('families_side',[0,12,15,27,30,33,36,39,42],'side',3,384)]:
 indices=list(indices);sheet=Image.new('RGB',(columns*size,((len(indices)+columns-1)//columns)*(size+20)),(25,27,29));draw=ImageDraw.Draw(sheet)
 for index,i in enumerate(indices):
  im=Image.open(root/f'captures/v{i:02d}_{pattern}.png').convert('RGB');im=im.resize((size,size));x=(index%columns)*size;y=(index//columns)*(size+20);sheet.paste(im,(x,y));draw.text((x+4,y+size),f'Variant {i:02d} | {pattern}',fill='white')
 sheet.save(root/f'sheets/{label}.jpg',quality=92)
