"""Single source of truth for warehouse objects, navigation and the layout report."""
import json,math
from pathlib import Path
R=Path(__file__).resolve().parents[1];objs=[];surfaces=[];spawns=[]
def obj(name,p,s,mat='concrete',tag='CLIMB_MANTLE',role='box',solid=True,block=False,**kw):
 d=dict(name=name,position=p,size=s,material=mat,tag=tag,role=role,solid=solid,block=block,**kw);objs.append(d);return d
def surface(x,z,w,d,y=0,low=None,ai=True):surfaces.append(dict(rect=[x,z,w,d],high=y,low=y if low is None else low,ai=ai))
def deck(name,x,z,w,d,y):
 obj(name,[x+w/2,y-.15,z+d/2],[w,.3,d],'steel','NO_GRIP');surface(x,z,w,d,y)
# Four floor slabs leave a real hole for the wave-9 pit panel.
for name,p,s,rect in [('west',[-16,-.3,0],[28,.6,30],[-30,-15,28,30]),('east',[16,-.3,0],[28,.6,30],[2,-15,28,30]),('south',[0,-.3,-8.5],[4,.6,13],[-2,-15,4,13]),('north',[0,-.3,8.5],[4,.6,13],[-2,2,4,13])]:
 obj('floor_'+name,p,s,'floor','SLIDE_OK');surface(*rect)
obj('pit_panel',[0,-.15,0],[4,.3,4],'floor','SLIDE_OK',role='pit');surface(-2,-2,4,4)
for side in [-1,1]:
 obj('wall_z_'+str(side),[0,7,side*15.25],[60,14,.5],'steel','WALLRUN_OK')
 obj('wall_x_'+str(side),[side*30.25,7,0],[.5,14,30],'concrete','WALLRUN_OK')
 deck('catwalk_'+str(side),-22,12.5 if side==1 else -15,44,2.5,4.5)
 # Two deliberate 3 m railing breaks at x=-10 and +10.
 rail_ranges = [(-22,-18.6),(-15.4,-14),(-12,-11.5),(-8.5,8.5),(11.5,15.4),(18.6,22)] if side==1 else [(-19.4,-11.5),(-8.5,8.5),(11.5,19.4)]
 for a,b in rail_ranges:
  obj('rail_%s_%s'%(side,a),[(a+b)/2,5.05,side*12.5],[b-a,1.1,.12],'steel','NO_GRIP',block=True)
 obj('runway_'+str(side),[0,2.5,side*10],[24,5,.25],'steel','WALLRUN_OK',block=True)
 for x in [-14.5,14.5]:obj('runway_launch_%s_%s'%(side,x),[x,.5,side*9],[2,1,2],'blue',block=True)
 # Staging door is an inward-opening boundary, not a new unreachable exterior room.
 obj('staging_'+str(side),[19,5.9,side*13.6],[4,2.8,.2],'blue','NO_GRIP',role='staging',block=False)
 for x in [-10,0,10]:obj('kick_pillar_%s_%s'%(side,x),[x,2.5,side*11.3],[1,5,1],'steel','WALLRUN_OK',block=True)
# Four 20 degree ramps. Offset north/south lanes avoid obstructing one another's run-outs.
run=round(4.5/math.tan(math.radians(20)),3)
for i,(x,north) in enumerate([(-17,True),(17,True),(-21,False),(21,False)]):
 z=12.5-run if north else -12.5
 high,low=(0,4.5) if north else (4.5,0)
 obj('slide_ramp_'+str(i),[x,2.25,z+run/2],[3,4.5,run],'floor','SLIDE_OK',role='ramp',rect=[x-1.5,z,3,run],high=high,low=low)
 surface(x-1.5,z,3,run,high,low)
# Mezzanine covers service corridor, with one ground stairwell and two open window approaches.
deck('mezzanine_west',-30,-12.5,4.5,25,4.5)
deck('mezzanine_east',-22.5,-12.5,.5,25,4.5)
deck('mezzanine_stair_head',-25.5,-12.5,3,1,4.5)
deck('mezzanine_south',-25.5,1.5,3,11,4.5)
for z in [-13.75,13.75]:deck('west_catwalk_link_'+str(z),-30,z-1.25,8,2.5,4.5)
obj('office_pillar',[-29,2.25,9],[1,4.5,1],'hazard','WALLRUN_OK',block=True)
for z in [-9,0,9]:obj('office_window_wall_'+str(z),[-22.1,6,z],[.2,3,4],'glass','NO_GRIP',block=True)
for z in [-5,5]:
 obj('office_window_sill_'+str(z),[-22.1,4.85,z],[.25,.7,3],'steel','CLIMB_MANTLE',block=True)
 obj('office_desk_'+str(z),[-28,5,z],[2,1,1],'olive',block=True)
# A smooth collision ramp under visual stair treads, within a single stairwell.
obj('office_stairs',[-24,2.25,-5],[3,4.5,13],'steel','CLIMB_MANTLE',role='ramp',rect=[-25.5,-11.5,3,13],high=4.5,low=0)
surface(-25.5,-11.5,3,13,4.5,0)
for i in range(15):obj('stair_tread_'+str(i),[-24,4.5-i*.3,-11.5+i*(13/15)],[3,.05,.8],'steel','NO_GRIP',solid=False)
# Dock riser remains a small 8 degree sill inside the 60x30 footprint.
for z in [-8,0,8]:
 obj('east_shutter_'+str(z),[29.6,2,z],[.3,4,5],'steel','NO_GRIP',role='door')
 obj('dock_baffle_'+str(z),[27.2,1.8,z+2.4],[3.6,3.6,.3],'olive','NO_GRIP',block=True)
 obj('dock_ramp_'+str(z),[24,.28,z],[4,.56,4],'floor','SLIDE_OK',role='dock')
 surfaces.append(dict(rect=[22,z-2,4,4],high=.56,low=0,ai=True,axis='x'))
 deck('dock_platform_'+str(z),26,z-2,4,4,.56)
obj('west_door',[-29.6,2,0],[.3,4,4],'olive','NO_GRIP',role='door')
obj('west_spawn_baffle',[-26,1.8,0],[.25,3.6,4],'olive','NO_GRIP',block=True)
for z in [-10,10]:obj('service_fence_'+str(z),[-26,1.5,z],[.08,3,4],'fence','NO_GRIP',block=True)
# Six forklift assemblies: collision envelopes stay below 2m; three x lanes remain clear.
for i,(x,z) in enumerate([(x,z) for x in [-7.5,7.5] for z in [-7,0,7]]):
 obj('forklift_'+str(i),[x,1,z],[4,2,2],'yellow',role='forklift',block=True)
# 12 barriers; four use 1.1m clearance rather than impossible 0.9m for 1m diameter.
for i,(x,z) in enumerate([(x,z) for x in [-4.5,4.5] for z in [-8,-4,0,4,8,9]]):
 if i in [0,3,6,9]:
  obj('slide_gate_'+str(i),[x,1.2,z],[2.5,.2,.4],'hazard','NO_GRIP',block=True)
  for side in [-1,1]:obj('slide_gate_post_%s_%s'%(i,side),[x+side*1.2,.55,z],[.15,1.1,.4],'steel','NO_GRIP',block=True)
 else:obj('barrier_'+str(i),[x,.5,z],[2.5,1,.45],'hazard',block=True)
# Mantle clusters are on five lateral approaches, outside clear longitudinal sprint lanes.
for i,(x,z) in enumerate([(-7,-8),(-7,3),(7,-8),(7,3),(-7,8)]):
 for j,h in enumerate([1,1.4,1.8]):
  obj('mantle_%s_%s'%(i,j),[x+(j-1)*2.5,h/2,z],[1,h,1],['red','blue','olive'][i%3],block=True)
# Container stair stacks provide two additional player-only routes.
for side in [-1,1]:
 for j,h in enumerate([1,2,3,4.5]):obj('container_step_%s_%s'%(side,j),[side*(13.7+j*.65),h/2,side*(9+j*.95)],[2,h,2],'blue' if side==1 else 'red',block=True)
for i,(x,y,z) in enumerate([(-4,5.5,-5),(4,6.5,-5),(-4,7,5),(4,8,5)]):
 obj('hanging_crate_'+str(i),[x,y,z],[2,1,2],'olive',block=False)
 for dx in [-.8,.8]:obj('chain_%s_%s'%(i,dx),[x+dx,(y+14)/2,z],[.05,14-y,.05],'steel','NO_GRIP',solid=False)
# Four readable quadrant landmarks, distinct silhouettes and colors.
obj('red_crane_beam',[-14,11,6],[18,.6,.7],'red','NO_GRIP',solid=False)
obj('blue_stack',[13,1.5,-12],[4,3,2],'blue',block=True)
obj('hazard_landmark',[-14.5,3,-9],[1.1,6,1.1],'hazard','WALLRUN_OK',block=True)
obj('broken_water_tank',[25,2,12],[3,4,3],'steel','NO_GRIP',role='tank',block=True)
for i,x in enumerate([-5,5]):
 obj('crane_load_'+str(i),[x,9,2],[10,2,5],'red' if i==0 else 'blue','NO_GRIP',role='crane')
 obj('crane_wire_'+str(i),[x,12,2],[.08,4,.08],'steel','NO_GRIP',solid=False)
for i,(x,z) in enumerate([(-13,-8),(13,-8),(-13,8),(13,8)]):obj('fuel_'+str(i),[x,.7,z],[.7,1.4,.7],'red','NO_GRIP',role='fuel',block=True)
for i,x in enumerate([-10,10]):obj('electric_'+str(i),[x,.025,4],[3,.05,2],'steel','NO_GRIP',role='electric',solid=False)
# Fixed resupply locations: seven stations cannot all satisfy 15m spacing in the requested zones.
for i,p in enumerate([[-27,.5,-12],[27,.5,-12],[-27,.5,12],[27,.5,12]]):obj('ammo_'+str(i),p,[.8,1,.6],'olive','NO_GRIP',role='ammo')
for i,p in enumerate([[-27,5,0],[26,.5,0]]):obj('health_'+str(i),p,[.8,1,.5],'red','NO_GRIP',role='health')
obj('weapon_cache',[0,5,13.8],[1.4,1,.7],'blue','NO_GRIP',role='cache')
obj('zipline_start',[-12.8,5.5,13.5],[.3,.3,.3],'yellow','NO_GRIP',role='zipline',solid=False)
obj('zipline_lead',[-12.8,5.55,12.65],[.04,.04,1.7],'steel','NO_GRIP',solid=False)
obj('zipline_cable',[-12.8,3.325,7.9],[.04,.04,8.98],'steel','NO_GRIP',solid=False)
# Decorative floor routes, weathering and roof steel. Non-colliding detail stays out of runways.
for x in [-12,0,12]:obj('sprint_lane_'+str(x),[x,.012,0],[.08,.01,19],'yellow','NO_GRIP',solid=False)
for x in [-8,8]:
 for z in [-5,5]:
  obj('skylight_%s_%s'%(x,z),[x,13.95,z],[4,.08,4],'glass','NO_GRIP',solid=False)
for x in [-28,-20,-12,-4,4,12,20,28]:
 obj('roof_beam_'+str(x),[x,13.7,0],[.2,.45,30],'steel','NO_GRIP',solid=False)
 obj('strip_light_'+str(x),[x,13.4,0],[.12,.08,22],'white','NO_GRIP',solid=False)
for i,(x,z) in enumerate([(-23,-8),(-23,8),(0,-6),(0,6),(23,-8),(23,8)]):obj('light_'+str(i),[x,11,z],[1,1,1],'white','NO_GRIP',role='light',solid=False)
for i,(x,z) in enumerate([(-5,-6),(4,6),(-19,0),(24,4)]):obj('oil_'+str(i),[x,.018,z],[2,.01,1.4],'oil','NO_GRIP',solid=False)
for i,(x,z) in enumerate([(x,z) for x in [-18,18] for z in range(-8,9,2)]):obj('tire_'+str(i),[x,.02,z],[.12,.01,1.5],'oil','NO_GRIP',solid=False)
# Roof panels leave four exact 4x4 skylight openings.
xs=[-30,-10,-6,6,10,30];zs=[-15,-7,-3,3,7,15]
for a,b in zip(xs,xs[1:]):
 for c,d in zip(zs,zs[1:]):
  if a in [-10,6] and c in [-7,3]:continue
  obj('roof_%s_%s'%(a,c),[(a+b)/2,14.15,(c+d)/2],[b-a,.3,d-c],'steel','NO_GRIP')
# Spawn descriptors use ground landing points; skylight height is separate.
for z in [-8,0,8]:spawns.append(dict(name='EAST '+str(z),position=[28,.64,z],type='east',capacity=4,warning=5,unlock=1,cue='Amber beacon + gear/siren',door='east_shutter_'+str(z)))
spawns.append(dict(name='WEST',position=[-28,.08,0],type='west',capacity=4,warning=5,unlock=1,cue='Red beacon + distinct low siren',door='west_door'))
for x in [-8,8]:
 for z in [-5,5]:spawns.append(dict(name='SKY %s %s'%(x,z),position=[x,14,z],landing=[x,.08,z],type='sky',capacity=4,warning=2,unlock=3,cue='Red landing marker, 3-second rope descent'))
for side in [-1,1]:spawns.append(dict(name='CATWALK '+str(side),position=[19,4.58,side*14.2],type='catwalk',capacity=3,warning=3,unlock=5,cue='Red beacon + staging door',door='staging_'+str(side)))
for i,s in enumerate(spawns):
 p=s.get('landing',s['position']);obj('spawn_beacon_'+str(i),[p[0],p[1]+2,p[2]],[.2,.3,.2],'amber','NO_GRIP',solid=False,role='beacon')
data=dict(objects=objs,surfaces=surfaces,spawns=spawns)
(R/'data/warehouse.json').write_text(json.dumps(data,indent=2)+'\n')
lines=['# Warehouse revamp — layout report','', '## 1. Design summary','', 'A 60 × 30 m shipping warehouse replaces the open testing yard: a cluttered central forklift zone, four offset slide ramps, a west office fallback, steel perimeter decks, east loading breaches and readable quadrant landmarks. Wave events progressively close a runway, cut catwalk lighting and lower a central pit. Shootable crane loads, fuel, pulsing grates and distributed resupply make position matter. All coordinates use X east, Z north and Y up; dimensions below are bounding envelopes with positions at their centers. Assemblies list one gameplay envelope; their decorative children remain inside it.','', '## 2. Object table','', '| Name | Position (X,Y,Z) m | Size W×H×D m | Material tag | Purpose / material |','|---|---|---|---|---|']
for o in objs:lines.append('| %s | %s | %s | %s | %s / %s |'%(o['name'],tuple(o['position']),' × '.join(str(v) for v in o['size']),o['tag'],o['role'],o['material']))
lines+=['','## 3. Spawn table','','| Name | Position | Type / capacity | Trigger | Cue | Warning |','|---|---|---|---|---|---|']
for s in spawns:lines.append('| %s | %s | %s / %s | Wave %s+ | %s | %ss |'%(s['name'],tuple(s['position']),s['type'],s['capacity'],s['unlock'],s['cue'],s['warning']))
lines+=['','## 4. Wave-event table','','| Wave / trigger | Effect | Geometry |','|---|---|---|','| 3, round start | North runway obstruction appears at round start | 3×3×1 m collapsed shutter at (0,1.5,9) |','| 6, round start | White overhead lights switch to low-energy red emergency lighting | Six existing fixtures; no added lights |','| 9, round start | Central 4×4 m panel lowers 1 m; add escape ramp and rebuild navigation | Center (0,-1.15,0), ramp rises back to floor |','','## 5. Assumptions','', '- A 4.5 m rise at 20° requires 12.36 m horizontal run / 13.16 m slope length; elevation and angle take priority over the contradictory 12 m length.', '- Catwalks are inset inside the footprint, centered at Z ±13.75. Rails have 3 m jump-down gaps; deck slabs remain continuous so baseline AI does not need jump links.', '- Slide-under clearance is 1.1 m: a capsule of radius 0.5 m cannot fit through a 0.9 m opening. The new-map standing capsule is 1.8 m, crouched height 1.0 m.', '- Ramps are offset laterally to keep opposing descents clear. Mantle clusters occupy approach lanes rather than all three designated longitudinal sprint lanes.', '- Ground breaches use east and west as two distinct types on waves 1–2. Safe-spawn distance and visibility checks take precedence over simultaneous/batched spawning; batches may be deferred.', '- Seven fixed supply points in the requested zones cannot all preserve 15 m spacing: each health station is approximately 12–13 m from the two corner ammo crates. These explicit exceptions preserve the requested station locations; all other supply pairs are at least 15 m apart.', '- Staging access is represented by concealed catwalk entry bays; external 4×6 m rooms would exceed the strict footprint. The player can enter after the staging door opens.', '- Functional alarms are synthesized, not recorded shouting, boot or plasma-tool samples. Rope descents are implemented; glass-crash animation remains an asset follow-up.', '- The zipline descends around the west end of the runway wall to (-12.8,0.1,4), keeping its swept player capsule clear of the wall.', '- Breach doors open when the warning starts; the cue is a single alarm/countdown rather than staged tool and boot sounds.', '- Cranes use 10×5 m warning/damage footprints. Grates pulse every six world seconds with a one-second visual tell. Stations are proximity-activated once per wave.', '- Navigation is a layered AStar graph sampled from the same surfaces as collision, not a baked navmesh. Four ramp routes and the stairwell connect to the killzone. Wave-9 pit changes rebuild the graph; remaining platform gaps are player-only.', '- Draw-call and GPU budgets require profiling on target hardware. The design uses six fixed dynamic lights plus the player muzzle light; beacons and strips are emissive meshes.', '', '## 6. Top-down map','', 'Each character represents 2×2 m. North (+Z) is at the top. The map is 30 columns × 15 rows; sub-cell details are in the object table.','', '```']
grid=[['.' for _ in range(30)] for _ in range(15)]
for row in range(15):
 for col in range(30):
  x=-29+col*2;z=14-row*2
  if x<-22:grid[row][col]='M' if x>-26 else 'W'
  elif x>22:grid[row][col]='D'
  elif abs(z)>12:grid[row][col]='C'
  if abs(abs(z)-10)<1.1 and abs(x)<=12:grid[row][col]='='
for o in objs:
 marks={'forklift':'F','ramp':'/','crane':'H','fuel':'B','electric':'~','ammo':'A','health':'+','cache':'K','pit':'P','tank':'T'}
 if o['role'] in marks:
  x,y,z=o['position'];c=min(29,max(0,int((x+30)/2)));r=min(14,max(0,int((15-z)/2)));grid[r][c]=marks[o['role']]
for s in spawns:
 x,y,z=s['position'];grid[min(14,max(0,int((15-z)/2)))][min(29,max(0,int((x+30)/2)))]=dict(east='E',west='W',sky='S',catwalk='N')[s['type']]
lines+=[''.join(r) for r in grid]+['```','','M office, W service/west breach, D dock, C catwalk, = runway, / ramp/stairs, F forklift, H crane load, B barrel, ~ electric grate, A ammo, + health, K weapon cache, P pit, T tank, E east breach, S skylight, N catwalk staging.']
(R/'docs/WAREHOUSE_LAYOUT.md').write_text('\n'.join(lines)+'\n')
print(len(objs),'objects',len(spawns),'spawns')
