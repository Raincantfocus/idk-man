extends SceneTree
const Actor=preload("res://scripts/ragdoll/anatomical_actor.gd")
const Pool=preload("res://scripts/death/ragdoll_budget.gd")
var settings: Dictionary
var results: Array=[]
func _initialize() -> void:call_deferred("run")
func run() -> void:
 settings=JSON.parse_string(FileAccess.get_file_as_string("res://data/ragdoll/settings.json"))
 var world:=Node3D.new();root.add_child(world)
 var floor:=StaticBody3D.new();floor.collision_layer=1;world.add_child(floor);floor.position.y=-.25
 var col:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=Vector3(50,.5,50);col.shape=shape;floor.add_child(col)
 var directions: Dictionary={"front":Vector3(0,0,-1),"back":Vector3(0,0,1),"left":Vector3(1,0,0),"right":Vector3(-1,0,0)}
 for role: String in settings.roles:
  for direction: String in directions:
   var tune: Dictionary=settings.duplicate(true);tune.mass_role=role
   var pool:=Pool.new();pool.configure(tune);var actor:=Actor.new();world.add_child(actor);actor.setup(tune,pool)
   for i: int in 3:await physics_frame
   assert(actor.physical.size()==16)
   var probe:=preload("res://scripts/ragdoll/skin_probe.gd").new();probe.setup(actor)
   var peak_skin: float=1.0
   actor.begin_death(directions[direction],PackedStringArray(["rifle"]))
   var peak_separation: float=0.0;var peak_penetration: float=0.0;var angle_streak: int=0;var max_streak: int=0
   for frame: int in 180:
    await physics_frame
    if frame%15==0:peak_skin=maxf(peak_skin,probe.measure(actor))
    peak_separation=maxf(peak_separation,actor.joint_error())
    var bad: bool=false
    for row: Dictionary in actor.joint_metrics.values():bad=bad or float(row.angle_error_degrees)>5.0
    angle_streak=angle_streak+1 if bad and actor.is_simulating() else 0;max_streak=maxi(max_streak,angle_streak)
    for name: String in actor.points():peak_penetration=maxf(peak_penetration,actor.query.penetration(world.get_world_3d().direct_space_state,name,actor.points()[name],actor.excluded).length())
   var row: Dictionary={"initial_joint_metrics":actor.initial_joint_metrics,"selected_clip":String(actor.selected.id) if actor.selected!=null else "none","handoff_reason":actor.reason,"authored_seconds":actor.elapsed,"worst_skin_edge":probe.worst_edge,"worst_joint_metrics":actor.worst_joint_metrics,"sampled_skin_edges":probe.edges.size(),"max_sampled_skin_edge_ratio":peak_skin,"role_mass_profile":role,"direction":direction,"body_count":actor.physical.size(),"max_joint_separation_cm":peak_separation*100.,"max_angle_error_degrees":actor.max_angle_error,"angle_violation_ticks":max_streak,"max_speed_m_s":actor.max_body_speed,"max_spin_rad_s":actor.max_body_spin,"max_proxy_penetration_cm":peak_penetration*100.,"guard_freezes":actor.guard_freezes,"no_valid_snapshot_ticks":actor.guard_missing_snapshot,"guard_cpu_us_per_tick":float(actor.guard_cpu_us)/maxi(actor.guard_frames,1),"frozen":actor.state==Actor.State.FROZEN,"exclusions":actor.excluded_pairs,"one_handoff":actor.handoff_count==1,"pass":actor.guard_freezes==0 and actor.guard_missing_snapshot==0 and actor.handoff_count==1 and peak_separation<=.01 and max_streak<=2 and peak_penetration<=.02 and peak_skin<=1.1}
   results.append(row);print("ANATOMICAL_CASE ",JSON.stringify(row));actor.free();await physics_frame
 var file:=FileAccess.open("res://data/ragdoll/rig_test_report.json",FileAccess.WRITE)
 file.store_string(JSON.stringify({"engine":Engine.get_version_info().string,"renderer":"headless","hardware_frame_cost_valid":false,"scope":"20 role-mass/direction rifle cases, 180 ticks each; shared review mesh, not five approved role assets","skin_stretch_measured":"Sparse edges outside corrective zones, every 15th tick; not exhaustive","cases":results},"  "));file.close();quit()
