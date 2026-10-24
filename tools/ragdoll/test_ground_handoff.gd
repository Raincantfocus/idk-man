extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var tuning: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/ragdoll/settings.json"))
 var world:=Node3D.new();root.add_child(world)
 var floor:=StaticBody3D.new();floor.collision_layer=1;floor.position.y=-.25;world.add_child(floor)
 var shape:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(40,.5,40);shape.shape=box;floor.add_child(shape)
 var rows: Array=[]
 for file: String in DirAccess.get_files_at(tuning.clip_directory):
  if not file.ends_with(".tres"):continue
  var clip: Resource=load(String(tuning.clip_directory)+"/"+file)
  var pool:=preload("res://scripts/death/ragdoll_budget.gd").new();pool.configure(tuning)
  var actor:=preload("res://scripts/ragdoll/anatomical_actor.gd").new();world.add_child(actor);actor.setup(tuning,pool);actor.clips=[clip]
  for i: int in 3:await physics_frame
  var direction: Vector3={"front":Vector3(0,0,-1),"back":Vector3(0,0,1),"right":Vector3(-1,0,0)}[String(clip.direction)]
  var wall:=StaticBody3D.new();wall.collision_layer=1;world.add_child(wall)
  var chest: Array=clip.clearance_samples[0].points.Chest;wall.position=Vector3(chest[0],chest[1],chest[2])
  var obstruction:=CollisionShape3D.new();var obstruction_shape:=BoxShape3D.new();obstruction_shape.size=Vector3(.4,.4,.4);obstruction.shape=obstruction_shape;wall.add_child(obstruction)
  for i: int in 2:await physics_frame
  assert(not actor.query.clip_clear(world.get_world_3d().direct_space_state,clip,Transform3D.IDENTITY,actor.excluded),"Wall was ignored: "+String(clip.id))
  wall.free()
  for i: int in 2:await physics_frame
  if clip.flying:
   var choice: Dictionary=actor.query.choose(world.get_world_3d().direct_space_state,[clip],clip.direction,PackedStringArray(["rifle"]),Transform3D.IDENTITY,actor.excluded,clip.requires_crouch)
   assert(choice.clip==null,"Rifle selected flying death")
  actor.begin_death(direction,PackedStringArray(["shotgun" if clip.flying else "rifle"]),Vector3.ZERO,clip.requires_crouch)
  var selected: bool=actor.selected!=null
  var animation_ticks: int=0
  for frame: int in 180:
   await physics_frame
   if actor.state==actor.State.ANIMATING:animation_ticks+=1
   if actor.handoff_count>0:break
  assert(selected and actor.handoff_count==1,"Selection/handoff failed: "+String(clip.id))
  assert(actor.reason in ["planned","body_blocked"] or (clip.flying and actor.reason=="no_support"),"Unexpected interruption: "+actor.reason)
  rows.append({"wall_rejected":true,"clip":String(clip.id),"selected":selected,"animation_ticks":animation_ticks,"authored_elapsed":actor.elapsed,"planned_handoff":clip.handoff_time,"reason":actor.reason,"handoffs":actor.handoff_count,"lift_mm":clip.presentation_offset.y*1000})
  print("GROUND_CASE ",JSON.stringify(rows.back()));actor.free();await physics_frame
 var output:=FileAccess.open("res://data/ragdoll/ground_handoff_report.json",FileAccess.WRITE);output.store_string(JSON.stringify({"engine":Engine.get_version_info().string,"scope":"Single-clip selection on flat floor; not full ragdoll acceptance","cases":rows},"  "));output.close()
 world.free();quit()
