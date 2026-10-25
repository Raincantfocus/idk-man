extends SceneTree
var results: Array=[]
func _initialize() -> void:call_deferred("run")
func click(scene: Node, action: String) -> void:
 for button: Node in scene.find_children("*","Button",true,false):
  if button.get_meta("action",button.text)==action:
   assert(not button.disabled,action);button.pressed.emit();return
 assert(false,"Missing button: "+action)
func run() -> void:
 var settings: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/ragdoll/settings.json"))
 var cases: Array=[]
 for file: String in DirAccess.get_files_at(settings.clip_directory):
  if file.ends_with(".tres"):cases.append({"clip":String(load(String(settings.clip_directory)+"/"+file).id),"scenario":"open"})
 for scenario: String in ["wall_touch","wall_20cm","crate","corridor","stairs","ledge"]:cases.append({"clip":"death","scenario":scenario})
 for test: Dictionary in cases:
  var scene: Node=load("res://ragdoll_review.tscn").instantiate();root.add_child(scene)
  assert(not scene.preview_mode,"Normal playback must include collision and ragdoll")
  click(scene,String(test.scenario));click(scene,"Clip: "+String(test.clip))
  assert(not scene.preview_mode,"Clip click silently enabled collision bypass")
  var seen_physics: bool=false;var frames: int=0;var start_hip:=Vector3.ZERO;var movement: float=0.0;var guard_freezes: int=0;var peak_penetration: float=0.0
  for tick: int in 660:
   await physics_frame
   var actor: Node=scene.actor
   if actor.is_simulating():
    if not seen_physics:start_hip=actor.physical.Hips.global_position
    seen_physics=true;frames+=1
    movement=maxf(movement,start_hip.distance_to(actor.physical.Hips.global_position))
   guard_freezes=actor.guard_freezes
   if seen_physics and tick%5==0:peak_penetration=maxf(peak_penetration,actor.body_penetration_m())
  var actor: Node=scene.actor
  var supported_frozen: bool=actor.state==actor.State.FROZEN and actor._can_freeze_pose()
  var final_penetration: float=actor.body_penetration_m()
  var passed: bool=final_penetration<=float(settings.penetration_limit_m) and seen_physics and frames>=6 and movement>.03 and movement<12.0 and guard_freezes==0 and actor.handoff_count==1 and actor.lethal_events_received==1
  # The ledge may legitimately leave the platform and remain airborne.
  if test.scenario=="open":passed=passed and supported_frozen
  if test.scenario=="open" and String(test.clip).ends_with("death_from_right"):
   passed=passed and actor.elapsed>=.2 # Regression: planted-foot drift used to abort at 17–33 ms.
  var row: Dictionary={"peak_body_penetration_mm":peak_penetration*1000,"final_body_penetration_mm":final_penetration*1000,"clip":test.clip,"scenario":test.scenario,"physics_frames":frames,"hip_movement_m":movement,"state":actor.State.keys()[actor.state],"supported_frozen":supported_frozen,"guard_freezes":guard_freezes,"constraint_recoveries":actor.constraint_recoveries,"initial_contact_shift_m":actor.max_contact_shift_m,"authored_seconds":actor.elapsed,"handoff_reason":actor.reason,"handoff_count":actor.handoff_count,"lethal_events":actor.lethal_events_received,"pass":passed}
  results.append(row);print("TRANSITION_CASE ",JSON.stringify(row));scene.free();await physics_frame
 var file:=FileAccess.open("res://data/ragdoll/playback_transition_report.json",FileAccess.WRITE);file.store_string(JSON.stringify({"engine":Engine.get_version_info().string,"scope":"Functional transitions and collider-based settling; not anatomical or skin approval","cases":results},"  "));file.close()
 var passed: bool=results.all(func(row:Dictionary)->bool:return row.pass)
 print("TRANSITION_SUITE_PASS ",passed);quit(0 if passed else 1)
