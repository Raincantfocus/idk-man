"""Executable Rev B layout. The detailed 30x15 / 6x6 specification wins over old diagram."""
import json,math
from pathlib import Path
root=Path(__file__).resolve().parents[2];out=root/'data/maps/warehouse_rev_b.json'
d={'revision':'PDF Rev B','bounds':[100,70],'shell_height':8,'killhouse':[30,15,3.5],'tower':[6,6,6],'catwalk_height':4,'props':[],'spawns':[],'internal_doors':[],'decisions':['Written six-room 30x15 killhouse replaces older 15x15 blueprint tower','Asset-table quantities used: 4 mid cars, 11 cars total','North is negative Z; origin centre; geometry in metres','Keep current wave gameplay pending user TDM decision']}
def prop(id,zone,kind,x,z,size=None,yaw=0):
 sizes={'car':[3.5,1.5,1.8],'container':[6,2.6,2.4],'barrier':[5,1.2,1],'dumpster':[2,1.4,1.4],'pallet':[2.4,.8,1],'crate':[2,2,2],'barrel':[.6,1,.6],'forklift':[2.4,2.2,1.5],'truck':[5,2.8,2.5],'lowwall':[5,1.2,.4],'woodwall':[4,2.4,.2],'fence':[5,2,.1]}
 d['props'].append({'id':id,'zone':zone,'kind':kind,'position':[x,0,z],'size':size or sizes[kind],'yaw_degrees':yaw,'bullet_permeable':kind in ['barrel','pallet','fence']})
for team,sign in [('Alpha',-1),('Bravo',1)]:
 for i,x in enumerate([-35,-24,0,28]):d['spawns'].append({'id':team+str(i+1),'team':team,'position':[x,.05,sign*31.5],'yaw_degrees':180 if sign<0 else 0})
 for i,x in enumerate([-35,-12,16]):prop(team+'Car'+str(i+1),team,'car',x,sign*29)
 for i,x in enumerate([-24,28]):prop(team+'Wall'+str(i+1),team,'lowwall',x,sign*28.5)
 prop(team+'Dumpster',team,'dumpster',0,sign*28.5)
for i,(x,z) in enumerate([(-44,-18),(-29,-18),(-34,17)]):prop('W-P'+str(i+1),'West','pallet',x,z)
for i,(x,z) in enumerate([(-39,-18),(-39,-13),(-42,16),(-37,16)]):prop('W-CR'+str(i+1),'West','crate',x,z)
prop('W-F1','West','forklift',-44,-5);prop('W-D1','West','dumpster',-34,-7);prop('W-L1','West','lowwall',-35,3);prop('W-W1','West','woodwall',-28,9,yaw=90)
for i,(x,z) in enumerate([(-45,22),(-44,22),(-44.5,23)]):prop('W-B'+str(i+1),'West','barrel',x,z)
for i,(x,z) in enumerate([(-16,-19),(16,-19),(-16,19),(16,19)]):prop('M-CN'+str(i+1),'Mid','container',x,z)
for i,(x,z) in enumerate([(-20,-4),(20,-4),(-20,4),(20,4)]):prop('M-C'+str(i+1),'Mid','car',x,z)
for i,(x,z) in enumerate([(-15,-12),(15,-12),(-15,12),(15,12)]):prop('M-B'+str(i+1),'Mid','barrier',x,z)
for i,(x,z) in enumerate([(-21,-10),(21,-10),(-21,10),(21,10)]):prop('M-D'+str(i+1),'Mid','dumpster',x,z)
for i,(x,z) in enumerate([(-8,-11),(-7,-11),(-8,11),(-7,11),(7,-11),(8,-11),(7,11),(8,11)]):prop('M-BR'+str(i+1),'Mid','barrel',x,z)
for i,(x,z) in enumerate([(33,-19),(43,20)]):prop('E-T'+str(i+1),'East','truck',x,z)
for i,(x,z) in enumerate([(31,-7),(44,-7),(31,-3),(44,-3)]):prop('E-B'+str(i+1),'East','barrier',x,z)
prop('E-C1','East','car',38,4);prop('E-CN1','East','container',34,10,yaw=90)
for i,z in enumerate([-13,13]):prop('E-D'+str(i+1),'East','dumpster',44,z)
prop('E-L1','East','lowwall',36,22);prop('E-F1','East','fence',32,3)
for id,kind,x,z in [('R1a','barrel',-12,-5),('R1b','barrel',-11,-5),('R2','crate',0,-1.5),('R3','lowwall',10,-5),('R4','pallet',-11,5),('R5','dumpster',0,1.5),('R6a','barrel',12,5),('R6b','crate',10,5)]:prop(id,'Killhouse',kind,x,z)
# Ten partition openings: eight across column walls, two across row wall.
for x in [-5,5]:
 for z in [-6.4,-4.1,4.1,6.4]:d['internal_doors'].append({'axis':'x','x':x,'z':z,'width':1.6,'height':3.5})
for x in [-10,10]:d['internal_doors'].append({'axis':'z','x':x,'z':0,'width':2.0,'height':2.4})
out.write_text(json.dumps(d,indent=2)+'\n');print('layout',len(d['props']),'cover instances;',len(d['internal_doors']),'doors;',len(d['spawns']),'spawns')
