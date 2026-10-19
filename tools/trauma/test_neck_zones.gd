extends SceneTree
const Zone=preload("res://scripts/trauma/trauma_zone.gd")
const State=preload("res://scripts/trauma/zone_trauma_state.gd")
var count: int=0
func check(condition: bool, message: String) -> void:
 assert(condition,message);count+=1
func read_zone(name: String) -> Zone:
 var zone:=Zone.new();var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/trauma/"+name+"_zone.json"))
 for key: String in data:
  match key:
   "thresholds":zone.thresholds=PackedFloat32Array(data[key])
   "allowed_weapon_classes":zone.allowed_weapon_classes=PackedStringArray(data[key])
   "child_zones":zone.child_zones=PackedStringArray(data[key])
   _:zone.set(key,data[key])
 return zone
func _initialize() -> void:
 var definitions: Array=[read_zone("head"),read_zone("neck")]
 for zone: Zone in definitions:
  check(ResourceSaver.save(zone,"res://data/trauma/"+String(zone.id)+"_zone.tres")==OK,"Save typed Resource")
  check(not zone.gameplay_consequences,"Gameplay feature disabled")
 var previous: Dictionary={}
 for gore: int in 3:
  var state:=State.new();state.configure(definitions,1234)
  var events: Array=[];state.severed.connect(func(id: StringName,detail: Dictionary) -> void:events.append([id,detail]))
  check(state.resolve_bone(&"Head")==&"head","Reuse bone mapping")
  check(not state.apply_hit(1,&"neck",100,&"rifle",0,0,Vector3.RIGHT,Vector3.UP),"Energy reject")
  check(state.apply_hit(2,&"neck",12,&"rifle",0,5,Vector3.RIGHT,Vector3.UP),"Damage transition")
  check(state.states[&"neck"]==State.State.DAMAGED,"Damaged")
  check(not state.apply_hit(2,&"neck",100,&"rifle",0,5,Vector3.RIGHT,Vector3.UP),"Duplicate event")
  check(state.apply_hit(3,&"neck",25,&"rifle",0,5,Vector3.RIGHT,Vector3.UP),"Closed transition")
  check(state.states[&"neck"]==State.State.FRACTURED_CLOSED,"Closed")
  check(state.apply_hit(4,&"neck",30,&"rifle",0,5,Vector3.RIGHT,Vector3.UP),"Open transition")
  check(state.states[&"neck"]==State.State.FRACTURED_OPEN,"Open")
  check(state.apply_hit(5,&"neck",100,&"shotgun",1,5,Vector3.RIGHT,Vector3.UP),"Detach")
  check(state.states[&"head"]==State.State.DETACHED,"Child detached")
  check(events.size()==2,"One event per chain member")
  check(not state.apply_hit(6,&"head",100,&"rifle",0,5,Vector3.RIGHT,Vector3.UP),"Detached hit ignored")
  check(events[0][1].head_pop,"Close shotgun head-pop request")
  check(rad_to_deg((events[0][1].normal as Vector3).angle_to(Vector3.UP))<=30.01,"Tilt clamped")
  if gore>0:check(state.states==previous,"Gore-independent state")
  previous=state.states.duplicate()
  var repeated:=State.new();repeated.configure(definitions,1234);var repeated_events: Array=[]
  repeated.severed.connect(func(id: StringName,detail: Dictionary) -> void:repeated_events.append([id,detail]))
  repeated.apply_hit(1,&"neck",100,&"shotgun",1,5,Vector3.RIGHT,Vector3.UP)
  check(events==repeated_events,"Separate seeded cosmetic RNG")
 var far_state:=State.new();far_state.configure(definitions,41);var far_events: Array=[]
 far_state.severed.connect(func(id: StringName,detail: Dictionary) -> void:far_events.append([id,detail]))
 check(far_state.apply_hit(100,&"head",100,&"shotgun",8,10,Vector3.UP,Vector3.UP),"Far shotgun transition")
 check(not far_events[0][1].head_pop and far_events[0][1].cap_weapon=="rifle","Far shotgun uses bullet tear family")
 print("NECK_ZONE_TESTS ",count," passed");quit()
