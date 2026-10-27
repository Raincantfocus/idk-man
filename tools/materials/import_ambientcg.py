"""Import a user-supplied ambientCG ZIP into shared Godot PBR textures.

Usage: python tools/materials/import_ambientcg.py Concrete042_2K-JPG.zip --asset-id Concrete042
Does not switch runtime materials. Records archive/map hashes and channel conversions.
"""
from pathlib import Path
from io import BytesIO
import argparse,hashlib,json,re,zipfile
from PIL import Image,ImageOps

CHANNELS={'albedo':'Color','normal_gl':'NormalGL','normal_dx':'NormalDX','ao':'AmbientOcclusion','roughness':'Roughness','metallic':'Metalness','height':'Displacement'}

def import_pack(archive,asset_id,output_root,default_metallic=0,max_size=2048):
    archive=Path(archive);output_root=Path(output_root)
    if not re.fullmatch(r'[A-Za-z][A-Za-z0-9_-]*',asset_id):raise ValueError('Invalid asset ID')
    if default_metallic not in (0,1):raise ValueError('Default metallic must be 0 or 1')
    if max_size not in (512,1024,2048,4096):raise ValueError('Choose a supported power-of-two size')
    maps={};sources={}
    with zipfile.ZipFile(archive) as z:
        for channel,suffix in CHANNELS.items():
            found=[i for i in z.infolist() if re.fullmatch(re.escape(asset_id)+r'_[^/]+_'+suffix+r'\.(png|jpg|jpeg)',Path(i.filename).name,re.I)]
            if len(found)>1:raise ValueError(f'Ambiguous {channel} maps: {[i.filename for i in found]}')
            if not found:continue
            i=found[0]
            if i.file_size>128*1024*1024:raise ValueError('Map exceeds 128 MiB input limit')
            raw=z.read(i);image=Image.open(BytesIO(raw));image.load()
            if max(image.size)>8192:raise ValueError('Map exceeds 8K input limit')
            sources[channel]={'archive_member':i.filename,'sha256':hashlib.sha256(raw).hexdigest(),'size':list(image.size)}
            if channel not in ('albedo','normal_gl','normal_dx') and image.mode in ('I;16','I;16B','I'):
                image=image.convert('I').point(lambda value: (value+128)/257).convert('L')
            maps[channel]=image.convert('RGB' if channel in ('albedo','normal_gl','normal_dx') else 'L')
    for channel in ('albedo','roughness'):
        if channel not in maps:raise ValueError(f'Missing required {channel} map')
    if not ('normal_gl' in maps or 'normal_dx' in maps):raise ValueError('Missing tangent normal map')
    original_size=maps['albedo'].size
    if any(im.size!=original_size for im in maps.values()):raise ValueError('All source maps must have matching dimensions')
    scale=min(1,max_size/max(original_size));size=tuple(max(1,round(d*scale)) for d in original_size)
    maps={key:im.resize(size,Image.Resampling.LANCZOS) if im.size!=size else im for key,im in maps.items()}
    conversion='OpenGL source; green unchanged'
    normal=maps.get('normal_gl')
    if normal is None:
        r,g,b=maps['normal_dx'].split();normal=Image.merge('RGB',(r,ImageOps.invert(g),b));conversion='DirectX source; green inverted to OpenGL +Y'
    ao=maps.get('ao',Image.new('L',size,255));metal=maps.get('metallic',Image.new('L',size,255*default_metallic))
    orm=Image.merge('RGB',(ao,maps['roughness'],metal))
    destination=output_root/asset_id
    if destination.exists():raise FileExistsError(f'{destination} already exists; choose a staging directory or review/remove it explicitly')
    destination.mkdir(parents=True)
    output={'albedo.png':maps['albedo'],'normal.png':normal,'orm.png':orm}
    if 'height' in maps:output['height.png']=maps['height']
    for name,im in output.items():im.save(destination/name)
    report={'asset_id':asset_id,'declared_source':f'https://ambientcg.com/view?id={asset_id}',
            'license':'CC0 1.0 (ambientCG published licensing; supplied archive not authenticated against the blocked catalog)',
            'license_reference':'https://docs.ambientcg.com/license/',
            'archive_name':archive.name,'archive_sha256':hashlib.sha256(archive.read_bytes()).hexdigest(),
            'source_maps':sources,'output_size':list(size),'normal_conversion':conversion,
            'orm_channels':'R=AO, G=roughness, B=metallic; sampled as linear data',
            'defaults':{'ao':None if 'ao' in maps else 1,'metallic':None if 'metallic' in maps else default_metallic},
            'output_sha256':{name:hashlib.sha256((destination/name).read_bytes()).hexdigest() for name in output}}
    (destination/'provenance.json').write_text(json.dumps(report,indent=2)+'\n')
    return report

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('archive',type=Path);parser.add_argument('--asset-id',required=True)
    parser.add_argument('--output-root',type=Path,default=Path(__file__).resolve().parents[2]/'assets/ambientcg')
    parser.add_argument('--default-metallic',type=int,choices=(0,1),default=0)
    parser.add_argument('--max-size',type=int,choices=(512,1024,2048,4096),default=2048)
    args=parser.parse_args();print(json.dumps(import_pack(args.archive,args.asset_id,args.output_root,args.default_metallic,args.max_size),indent=2))
