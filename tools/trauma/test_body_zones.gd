extends SceneTree
const Library=preload("res://scripts/trauma/zone_library.gd")
const State=preload("res://scripts/trauma/zone_trauma_state.gd")
const Zone=preload("res://scripts/trauma/trauma_zone.gd")
const Cavity=preload("res://scripts/trauma/cavity_state.gd")
var checks: int=0
var failures: int=0
func check(ok: bool, message: String) -> void:
 if not ok:push_error(message);failures+=1;return
 checks+=1
func _initialize() -> void:
 var definitions: Array=Library.read_all()
 check(definitions.size()==22,"22 Resources")
 var map: Dictionary={}
 for zone: Zone in definitions:
  check(not map.has(zone.id),"Unique ID");map[zone.id]=zone
  check(not zone.gameplay_consequences,"Cosmetic only")
  check(ResourceSaver.save(zone,"res://data/trauma/"+String(zone.id)+"_zone.tres")==OK,"Resource save")
  var restored: Zone=load("res://data/trauma/"+String(zone.id)+"_zone.tres") as Zone
  check(restored.to_dictionary()==zone.to_dictionary(),"Resource roundtrip")
 for zone: Zone in definitions:
  for child: String in zone.child_zones:
   check(map.has(StringName(child)),"Existing child")
   check(map[StringName(child)].parent_zone==zone.id,"Reciprocal parent")
 var state:=State.new();state.configure(definitions,42)
 check(state.resolve_bone(&"LeftUpperLeg")==&"","Ambiguous bone rejected")
 check(state.resolve_bone(&"LeftUpperLeg",&"left_thigh")==&"left_thigh","Explicit region")
 check(state.resolve_bone(&"LeftUpperLeg",&"right_thigh")==&"","Wrong side rejected")
 check(not state.apply_hit(0,&"head",100,&"rifle",0,NAN,Vector3.UP,Vector3.UP),"Nonfinite energy rejected")
 for zone: Zone in definitions:
  state.configure(definitions,42)
  var events: Array=[]
  var callback: Callable=func(id: StringName,_detail: Dictionary) -> void:events.append(id)
  state.severed.connect(callback)
  check(state.apply_hit(1,zone.id,100,&"explosive",0,10,Vector3.RIGHT,Vector3.UP),"Hit transition")
  check(not state.apply_hit(1,zone.id,100,&"explosive",0,10,Vector3.RIGHT,Vector3.UP),"Idempotent event")
  if zone.can_sever:
   check(state.states[zone.id]==State.State.DETACHED,"Root detached")
   var pending: Array=[zone.id]
   while not pending.is_empty():
    var id: StringName=StringName(pending.pop_back())
    check(state.states[id]==State.State.DETACHED,"Child chain detached")
    check(events.count(id)==1,"Exactly one sever event")
    for child: String in map[id].child_zones:pending.append(StringName(child))
   check(state.states[&"chest"]!=State.State.DETACHED,"No upward sever propagation")
  else:
   check(events.is_empty(),"Cavity cannot directly sever")
   check(state.states[zone.id]==State.State.FRACTURED_OPEN,"Cavity trauma bounded")
  state.severed.disconnect(callback)
 var cfg: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/trauma/cavity_tuning.json"))
 var cavity:=Cavity.new();cavity.configure(PackedStringArray(cfg.zones),PackedFloat32Array(cfg.thresholds),float(cfg.settle_seconds))
 for id: StringName in [&"chest",&"abdomen",&"pelvis"]:
  cavity.apply_trauma(id,10);check(cavity.states[id]==Cavity.State.SURFACE_DAMAGED,"Surface cavity")
  cavity.apply_trauma(id,60);check(cavity.states[id]==Cavity.State.BARRIER_BREACHED,"Barrier cavity")
  cavity.apply_trauma(id,100);check(cavity.states[id]==Cavity.State.CONTENTS_EXPOSED,"Exposed cavity")
 cavity.advance(0);check(cavity.ages[&"chest"]==0,"Pause freezes settling")
 cavity.advance(1);check(cavity.states[&"chest"]==Cavity.State.CONTENTS_EXPOSED,"Scaled clock")
 cavity.advance(3);check(cavity.states[&"chest"]==Cavity.State.SETTLED,"Four seconds settling")
 cavity.apply_trauma(&"chest",10);check(cavity.states[&"chest"]==Cavity.State.SETTLED,"No regression")
 print("BODY_ZONE_TESTS ",checks," passed, ",failures," failed");quit(1 if failures>0 else 0)
