"""Generate the approved killhouse perimeter data/colliders; preserve main gameplay scene."""
from pathlib import Path
import json,re
root=Path(__file__).resolve().parents[2]
p=root/'data/maps/hangar_staging_layout.json';cfg=json.loads(p.read_text())
x0,x1=2.247910862565041,13.752089137434959
zn,zs=-11.758933169841766,-34.5
height,thickness=2.716,.15
# End faces stay inside the measured footprint so the north stair base stays clear.
for entry in cfg['egress']:entry['position'][2]=zn-thickness/2 if entry['id']=='north' else zs+thickness/2
segments=[]
def add(name,center,size):segments.append({'name':name,'center':center,'size':size})
for name,x in [('West',x0+thickness/2),('East',x1-thickness/2)]:add(name,[x,height/2,(zn+zs)/2],[thickness,height,zn-zs])
for e in cfg['egress']:
 x,_,z=e['position'];left,right=x-e['width']/2-.12,x+e['width']/2+.12;top=e['height']+.12
 for label,a,b in [('Left',x0+thickness,left),('Right',right,x1-thickness)]:add(e['id'].title()+label,[(a+b)/2,height/2,z],[b-a,height,thickness])
 add(e['id'].title()+'Header',[x,(height+top)/2,z],[right-left,height-top,thickness])
cfg['killhouse_enclosure']={'height_m':height,'thickness_m':thickness,'x_bounds':[x0,x1],'z_bounds':[zs,zn],'material':'shared warehouse Metal','segments':segments,'roof':'open','door_clear_width_m':1.2,'door_clear_height_m':2.2}
p.write_text(json.dumps(cfg,indent=2)+'\n')
lines=[f'[gd_scene load_steps={len(segments)+1} format=3]','']
vec=lambda a:'Vector3('+', '.join(f'{v:.9f}' for v in a)+')'
for s in segments:lines += [f'[sub_resource type="BoxShape3D" id="{s["name"]}"]',f'size = {vec(s["size"])}','']
lines += ['[node name="KillhousePerimeterCollision" type="StaticBody3D"]','']
for s in segments:lines += [f'[node name="{s["name"]}" type="CollisionShape3D" parent="."]',f'position = {vec(s["center"])}',f'shape = SubResource("{s["name"]}")','']
(root/'scenes/maps/killhouse_perimeter_collision.tscn').write_text('\n'.join(lines))
p=root/'scenes/maps/zero_line_hangar.tscn';s=p.read_text()
if 'killhouse_perimeter_collision.tscn' not in s:
 s=s.replace('load_steps=7','load_steps=8').replace('[sub_resource type="ProceduralSkyMaterial"','[ext_resource type="PackedScene" path="res://scenes/maps/killhouse_perimeter_collision.tscn" id="2"]\n\n[sub_resource type="ProceduralSkyMaterial"',1)
 s+='\n[node name="KillhousePerimeterCollision" parent="." instance=ExtResource("2")]\n'
for e in cfg['egress']:
 pattern=r'(\[node name="'+e['id'].title()+r'(?:Left|Right|Lintel)"[^\n]+\]\nposition = Vector3\([^,]+, [^,]+, )[^)]+(\))'
 s=re.sub(pattern,lambda m:m[1]+str(e['position'][2])+m[2],s)
p.write_text(s)
print('Generated',len(segments),'perimeter sections;',[(e['id'],e['position']) for e in cfg['egress']])
