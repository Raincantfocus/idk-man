extends SceneTree
var results: Array=[]
func _initialize() -> void:call_deferred("run")
func click(scene: Node, title: String) -> void:
 for button: Node in scene.find_children("*","Button",true,false):
  if button.get_meta("action",button.text)==title:
   assert(not button.disabled,title);button.pressed.emit();return
 assert(false,"Missing button: "+title)
func run() -> void:
 var scene: Node=load("res://ragdoll_review.tscn").instantiate();root.add_child(scene)
 click(scene,"Animation preview")
 var ids: Array=[]
 for clip: Resource in scene.actor.clips:ids.append(String(clip.id))
 for id: String in ids:
  click(scene,"Clip: "+id)
  for i: int in 5:await physics_frame
  assert(scene.preview_clip!=null and String(scene.preview_clip.id)==id)
  var before: Array=scene.actor.capture_pose()
  scene._physics_process(minf(.4,scene.preview_clip.duration*.5))
  var after: Array=scene.actor.capture_pose();var changed: int=0
  for i: int in before.size():
   if not before[i].is_equal_approx(after[i]):changed+=1
  assert(changed>0,"Static clip: "+id)
  scene._physics_process(scene.preview_clip.duration)
  assert(is_equal_approx(scene.preview_time,scene.preview_clip.duration))
  assert(scene.actor.handoff_count==0)
  results.append({"clip":id,"changed_bones":changed,"reached_end":true})
 click(scene,"rifle")
 for button: Node in scene.find_children("*","Button",true,false):
  for clip: Resource in scene.actor.clips:
   if button.get_meta("action",button.text)=="Clip: "+String(clip.id) and clip.flying:assert(button.disabled)
 for title: String in ["open","wall_touch","wall_20cm","crate","corridor","ledge","stairs"]:
  click(scene,title)
  for i: int in 5:await physics_frame
  assert(scene.preview_clip!=null and scene.preview_time>0.0)
 click(scene,"Pause");assert(paused)
 click(scene,"Restart");assert(not paused)
 click(scene,"Collision test")
 for i: int in 5:await physics_frame
 assert(not scene.preview_mode and scene.actor.lethal_events_received==1)
 print("PREVIEW_BUTTON_TEST_PASS ",JSON.stringify(results))
 scene.free();quit()
