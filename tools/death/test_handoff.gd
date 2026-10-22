extends SceneTree
const Actor=preload("res://scripts/death/death_actor.gd")
const Pool=preload("res://scripts/death/ragdoll_budget.gd")
var settings: Dictionary
var report: Array=[]
var frames: Array=[]
var world: Node3D
var checks: int=0
var capture_mode: bool=false
var capture_label: Label
func _initialize() -> void:call_deferred("run")
func box(position: Vector3,size: Vector3,dynamic: bool=false) -> PhysicsBody3D:
 var body: PhysicsBody3D=RigidBody3D.new() if dynamic else StaticBody3D.new();body.collision_layer=int(settings.prop_mask) if dynamic else int(settings.world_mask);body.collision_mask=21;world.add_child(body);body.position=position
 var collider:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=size;collider.shape=shape;body.add_child(collider)
 var mesh:=MeshInstance3D.new();var visual:=BoxMesh.new();visual.size=size;mesh.mesh=visual;body.add_child(mesh)
 if dynamic:(body as RigidBody3D).mass=25.0
 return body
func make_actor(pool: RefCounted,position: Vector3=Vector3.ZERO) -> Actor:
 var actor:=Actor.new();world.add_child(actor);actor.position=position;actor.setup(settings,pool);return actor
func run() -> void:
 capture_mode=OS.get_cmdline_user_args().has("capture")
 if capture_mode:DirAccess.make_dir_recursive_absolute("res://death_captures")
 settings=JSON.parse_string(FileAccess.get_file_as_string("res://data/death/settings.json"))
 var directions: Dictionary={"front":Vector3(0,0,-1),"back":Vector3(0,0,1),"left":Vector3(1,0,0),"right":Vector3(-1,0,0)}
 for scenario: String in ["open","wall_touch","wall_20cm","crate","corridor","ledge","stairs","explosion_pillar","adjacent","corpse_behind","second_hit","moving_prop","budget_full"]:
  if OS.get_cmdline_user_args().has("quick") and scenario!="open":continue
  for direction: String in directions:
   if capture_mode and not [scenario,direction] in [["stairs","back"],["wall_touch","front"],["adjacent","right"]]:continue
   await run_case(scenario,direction,directions[direction])
 var file:=FileAccess.open("res://data/death/handoff_capture_report.json" if capture_mode else "res://data/death/handoff_test_report.json",FileAccess.WRITE)
 file.store_string(JSON.stringify({"engine":Engine.get_version_info().string,"cases":report,"checks":checks,"all_acceptance_passed":report.all(func(row: Dictionary)->bool:return row.pass),"hardware_frame_cost_valid":false},"  "));file.close()
 file=FileAccess.open("res://data/death/handoff_capture_frames.json" if capture_mode else "res://data/death/handoff_frames.json",FileAccess.WRITE);file.store_string(JSON.stringify(frames));file.close()
 print("HANDOFF_TEST_COMPLETE cases=",report.size()," checks=",checks," failed=",report.filter(func(row: Dictionary)->bool:return not row.pass).size());quit()
func run_case(scenario: String,direction: String,incoming: Vector3) -> void:
 world=Node3D.new();root.add_child(world)
 if capture_mode:
  root.size=Vector2i(1000,900)
  var environment:=WorldEnvironment.new();environment.environment=Environment.new();environment.environment.background_mode=Environment.BG_COLOR;environment.environment.background_color=Color(.12,.15,.19);environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.environment.ambient_light_energy=.8;world.add_child(environment)
  var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-40,-30,0);light.light_energy=1.6;world.add_child(light)
  var camera:=Camera3D.new();camera.position=Vector3(3,2.3,4.8);camera.fov=48;world.add_child(camera);camera.look_at(Vector3(0,.9,0));camera.current=true
  var canvas:=CanvasLayer.new();canvas.process_mode=Node.PROCESS_MODE_ALWAYS;world.add_child(canvas);capture_label=Label.new();capture_label.position=Vector2(10,10);canvas.add_child(capture_label)
 if scenario=="ledge":box(Vector3(0,-.25,-2.4),Vector3(6,.5,5))
 else:box(Vector3(0,-.25,0),Vector3(20,.5,20))
 var spawn:=Vector3.ZERO;var prop: RigidBody3D
 match scenario:
  "wall_touch":box(Vector3(0,1,-.37),Vector3(5,2,.3))
  "wall_20cm":box(Vector3(0,1,-.57),Vector3(5,2,.3))
  "crate":box(Vector3(.5,.45,0),Vector3(.5,.9,.7))
  "corridor":
   box(Vector3(-.55,1,0),Vector3(.3,2,6));box(Vector3(.55,1,0),Vector3(.3,2,6))
  "stairs":
   spawn.y=.3
   for i: int in 3:box(Vector3(0,.15+float(i)*.15,float(i)),Vector3(5,.3+float(i)*.3,1))
  "explosion_pillar":box(Vector3(0,1.5,1.8),Vector3(.5,3,.5))
  "moving_prop":prop=box(Vector3(1.5,.6,0),Vector3(.3,.7,.5),true) as RigidBody3D
 var pool:=Pool.new();pool.configure(settings)
 var actor: Actor=make_actor(pool,spawn)
 var extras: Array=[]
 if scenario in ["adjacent","corpse_behind","budget_full"]:
  var count: int=6 if scenario=="budget_full" else 1
  for i: int in count:
   var position:=Vector3(float(i)*2.0+3,0,0) if count>1 else Vector3(.45,0,0) if scenario=="adjacent" else Vector3(0,0,-.8)
   extras.append(make_actor(pool,position))
 for i: int in 3:await physics_frame
 for other: Actor in extras:
  other.begin_death(Vector3(0,0,-1),PackedStringArray());other.notify_hit(true,Vector3.ZERO)
  if scenario=="corpse_behind":
   for tick: int in 120:await physics_frame
   assert(other.freeze_corpse(), "Corpse-behind fixture must start with a frozen corpse")
 var tags:=PackedStringArray(["shotgun"]) if scenario in ["open","explosion_pillar"] else PackedStringArray()
 var impulse:=Vector3(0,3,60) if scenario=="explosion_pillar" else Vector3.ZERO
 var initial_depth: float=0.0
 for name: String in actor.points():initial_depth=maxf(initial_depth,actor.query.penetration(world.get_world_3d().direct_space_state,name,actor.points()[name],actor.excluded).length())
 assert(actor.begin_death(incoming,tags,impulse));checks+=1
 assert(not actor.begin_death(incoming,tags,impulse));checks+=1
 var max_depth: float=0.0;var consecutive: Dictionary={};var longest: int=0;var peak_constraint: float=0.0;var query_us: int=0
 var captured_peak: float=-1.0
 for frame: int in 150:
  if frame==5 and scenario=="second_hit":actor.notify_hit(true,Vector3(2,0,2))
  if frame==5 and prop!=null:prop.linear_velocity=Vector3(-5,0,0)
  await physics_frame
  if not is_instance_valid(actor):break
  var begin: int=Time.get_ticks_usec();var points: Dictionary=actor.points();var depth_by_bone: Dictionary={}
  for name: String in points:
   var correction: Vector3=actor.query.penetration(world.get_world_3d().direct_space_state,name,points[name],actor.excluded);var depth: float=correction.length();depth_by_bone[name]=depth;max_depth=maxf(max_depth,depth)
   consecutive[name]=int(consecutive.get(name,0))+1 if depth>float(settings.penetration_limit_m) else 0;longest=maxi(longest,int(consecutive[name]))
  query_us+=Time.get_ticks_usec()-begin
  peak_constraint=maxf(peak_constraint,actor.joint_error())
  if capture_mode and max_depth>captured_peak:
   captured_peak=max_depth;paused=true
   capture_label.text="UNAPPROVED HANDOFF | %s / %s | frame %d\nReason %s | peak penetration %.1f mm | joint error %.1f mm\nDiagnostic capture; acceptance requires full logs" % [scenario,direction,frame,actor.reason,max_depth*1000,peak_constraint*1000]
   await process_frame
   await RenderingServer.frame_post_draw
   assert(root.get_texture().get_image().save_png("res://death_captures/"+scenario+"_"+direction+".png")==OK)
   paused=false
  frames.append({"case":scenario,"direction":direction,"frame":frame,"state":actor.state,"depth_m":depth_by_bone,"joint_anchor_error_m":actor.joint_error()})
 assert(actor.lethal_events_received==1 and actor.handoff_count==1);checks+=1
 var flying_legal: bool=actor.selected==null or not actor.selected.flying or tags.has("shotgun") or tags.has("high_caliber");assert(flying_legal);checks+=1
 var passed: bool=longest<=int(settings.penetration_frames_limit) and actor.max_handoff_pop<=float(settings.handoff_pop_limit_m) and peak_constraint<=0.02
 var row: Dictionary={"case":scenario,"direction":direction,"clip":String(actor.selected.id) if actor.selected!=null else "none","reason":actor.reason,"handoff_time":actor.elapsed,"max_depth_m":max_depth,"initial_depth_m":initial_depth,"longest_penetration_frames":longest,"handoff_pop_m":actor.max_handoff_pop,"max_joint_length_error_m":peak_constraint,"audit_query_cpu_us_per_tick":float(query_us)/150.0,"budget_evictions":pool.evictions,"pass":passed,"trace":actor.trace}
 report.append(row);print("HANDOFF_CASE ",scenario," ",direction," pass=",passed," reason=",actor.reason," depth=",max_depth," joint=",peak_constraint)
 world.free();await physics_frame
