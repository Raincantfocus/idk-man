extends RefCounted
## Presentation receives a copy of an already resolved gameplay hit.
## It never calls take_damage, awards a kill, spawns loot or draws gameplay RNG.
signal transition(zone: StringName, previous: int, next: int)
signal severed(zone: StringName, presentation: Dictionary)
const Zone=preload("trauma_zone.gd")
enum State { INTACT, DAMAGED, FRACTURED_CLOSED, FRACTURED_OPEN, DETACHED }
var zones: Dictionary={}
var trauma: Dictionary={}
var states: Dictionary={}
var applied_hits: Dictionary={}
var rng:=RandomNumberGenerator.new()
var gameplay_consequences: bool=false
func configure(definitions: Array, cosmetic_seed: int) -> void:
 zones.clear();trauma.clear();states.clear();applied_hits.clear();rng.seed=cosmetic_seed
 for zone: Zone in definitions:
  zones[zone.id]=zone;trauma[zone.id]=0.0;states[zone.id]=State.INTACT
func resolve_bone(bone: StringName) -> StringName:
 # Bone comes from the existing damage resolver; no physics layer is modified.
 for key: StringName in zones:
  if zones[key].bone==bone:return key
 return &""
func apply_hit(event_id: int, zone_id: StringName, damage: float, weapon: StringName, distance_m: float, energy: float, direction: Vector3, bone_axis: Vector3) -> bool:
 var hit_key: String=str(event_id)+":"+String(zone_id)
 if applied_hits.has(hit_key) or not zones.has(zone_id):return false
 var zone: Zone=zones[zone_id]
 if states[zone_id]==State.DETACHED or not String(weapon) in zone.allowed_weapon_classes or energy<zone.min_impact_energy:return false
 if not is_finite(damage) or not is_finite(distance_m) or not direction.is_finite() or not bone_axis.is_finite():return false
 applied_hits[hit_key]=true
 var falloff: float=clampf(1.0-maxf(distance_m,0)*zone.distance_falloff_per_m,0.1,1.0)
 trauma[zone_id]=minf(zone.trauma_hp,float(trauma[zone_id])+maxf(damage,0)*float(zone.weapon_multipliers.get(String(weapon),1.0))*falloff)
 var next: int=State.INTACT
 for threshold: float in zone.thresholds:
  if float(trauma[zone_id])>=threshold:next+=1
 if not zone.can_sever:next=mini(next,State.FRACTURED_OPEN)
 if float(trauma[zone_id])<zone.sever_threshold:next=mini(next,State.FRACTURED_OPEN)
 if next<=int(states[zone_id]):return false
 if next==State.DETACHED:
  var axis: Vector3=bone_axis.normalized() if not bone_axis.is_zero_approx() else Vector3.UP
  var incoming: Vector3=direction.normalized() if not direction.is_zero_approx() else axis
  if incoming.dot(axis)<0:incoming=-incoming
  var angle: float=axis.angle_to(incoming)
  var normal: Vector3=axis.slerp(incoming,minf(1.0,deg_to_rad(zone.max_tilt_degrees)/maxf(angle,.0001)))
  var detail: Dictionary={"root_zone":String(zone_id),"weapon":String(weapon),"cap_weapon":"rifle" if weapon==&"shotgun" and distance_m>zone.close_shotgun_m else String(weapon),"variant":rng.randi_range(0,2),"normal":normal,"direction":direction.normalized(),"spin":Vector3(rng.randf_range(-1,1),rng.randf_range(-1,1),rng.randf_range(-1,1)),"head_pop":weapon==&"shotgun" and distance_m<=zone.close_shotgun_m and zone_id in [&"head",&"neck"]}
  _detach_chain(zone_id,detail,{})
 else:_set_state(zone_id,next)
 return true
func _set_state(id: StringName, next: int) -> void:
 var previous: int=states[id]
 if next<=previous:return
 states[id]=next;transition.emit(id,previous,next)
func _detach_chain(id: StringName, detail: Dictionary, visiting: Dictionary) -> void:
 if visiting.has(id) or not zones.has(id) or states[id]==State.DETACHED:return
 visiting[id]=true;_set_state(id,State.DETACHED);severed.emit(id,detail.duplicate(true))
 for child: String in zones[id].child_zones:_detach_chain(StringName(child),detail,visiting)
