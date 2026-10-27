"""Synthetic fixtures verify channel packing; these are not ambientCG art assets."""
import importlib.util,tempfile,zipfile,json
from pathlib import Path
from io import BytesIO
from PIL import Image
spec=importlib.util.spec_from_file_location('importer',Path(__file__).with_name('import_ambientcg.py'));module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
with tempfile.TemporaryDirectory() as temp:
 root=Path(temp)
 def pack(name,channels):
  path=root/(name+'.zip')
  with zipfile.ZipFile(path,'w') as z:
   for channel,value in channels.items():
    buffer=BytesIO();Image.new('RGB',(8,8),value).save(buffer,format='PNG');z.writestr(name+'_2K-PNG_'+channel+'.png',buffer.getvalue())
  return path
 base={'Color':(120,130,140),'Roughness':(80,80,80),'NormalDX':(128,60,250)}
 archive=pack('Fixture',base)
 report=module.import_pack(archive,'Fixture',root/'out')
 assert Image.open(root/'out/Fixture/normal.png').getpixel((0,0))==(128,195,250)
 assert Image.open(root/'out/Fixture/orm.png').getpixel((0,0))==(255,80,0)
 assert report['defaults']=={'ao':1,'metallic':0}
 archive=pack('MetalFixture',{**base,'NormalGL':(130,140,250),'AmbientOcclusion':(35,35,35),'Metalness':(255,255,255)})
 module.import_pack(archive,'MetalFixture',root/'out')
 assert Image.open(root/'out/MetalFixture/normal.png').getpixel((0,0))==(130,140,250)
 assert Image.open(root/'out/MetalFixture/orm.png').getpixel((0,0))==(35,80,255)
 with zipfile.ZipFile(archive,'a') as z:
  buffer=BytesIO();Image.new('I;16',(8,8),32768).save(buffer,format='PNG');z.writestr('MetalFixture_2K-PNG_Displacement.png',buffer.getvalue())
 module.import_pack(archive,'MetalFixture',root/'height_out')
 assert Image.open(root/'height_out/MetalFixture/height.png').getpixel((0,0))==128
 try:module.import_pack(archive,'MetalFixture',root/'out');raise AssertionError('Overwrite accepted')
 except FileExistsError:pass
 try:module.import_pack(pack('Missing',{'Color':(1,1,1)}),'Missing',root/'out');raise AssertionError('Incomplete set accepted')
 except ValueError:pass
print('AMBIENTCG_IMPORT_TEST_PASS: GL priority, DX conversion, ORM packing/defaults, missing-map and overwrite rejection')
