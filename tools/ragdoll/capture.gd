extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 DirAccess.make_dir_recursive_absolute("res://ragdoll_captures")
 var report: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/ragdoll/rig_test_report.json"))
 var cases: Array=report.cases
 cases.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return float(a.max_joint_separation_cm)>float(b.max_joint_separation_cm))
 for row: Dictionary in cases.slice(0,3):
  var direction: String=row.direction
  var scene: Node=(load("res://ragdoll_review.tscn") as PackedScene).instantiate();root.add_child(scene);scene.settings.mass_role=row.role_mass_profile;scene.select("Collision test");scene.select("rifle");scene.select(direction)
  for i: int in 180:await physics_frame
  var actor: Node=scene.actor
  actor.simulator.physical_bones_stop_simulation();actor.simulator.active=false;actor.simulator.influence=0.0
  actor.restore_pose(actor.worst_pose);actor.state=actor.State.FROZEN
  actor.joint_metrics=actor.worst_joint_metrics;actor.frozen_joint_error=actor.worst_separation
  scene._physics_process(0.0)
  scene.label.text="RECORDED PEAK POSE REPLAY | "+String(row.role_mass_profile)+" / "+direction+"\n"+scene.label.text
  paused=true;await process_frame;await RenderingServer.frame_post_draw
  assert(root.get_texture().get_image().save_png("res://ragdoll_captures/"+String(row.role_mass_profile)+"_"+direction+".png")==OK)
  paused=false;scene.free();await physics_frame
 quit()
