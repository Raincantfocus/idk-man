extends SceneTree
const Actor=preload("res://scripts/death/death_actor.gd")
const Pool=preload("res://scripts/death/ragdoll_budget.gd")
var settings: Dictionary
var world: Node3D
func _initialize() -> void:call_deferred("run")
func spawn(pool: RefCounted,position: Vector3) -> Actor:
 var actor:=Actor.new();world.add_child(actor);actor.position=position;actor.setup(settings,pool);return actor
func run() -> void:
 settings=JSON.parse_string(FileAccess.get_file_as_string("res://data/death/settings.json"));world=Node3D.new();root.add_child(world)
 var floor:=StaticBody3D.new();floor.collision_layer=1;world.add_child(floor);floor.position.y=-.25
 var collision:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=Vector3(60,.5,60);collision.shape=shape;floor.add_child(collision)
 var pool:=Pool.new();pool.configure(settings)
 var actor: Actor=spawn(pool,Vector3.ZERO)
 for i: int in 3:await physics_frame
 actor.begin_death(Vector3(0,0,-1),PackedStringArray(["rifle"]))
 for i: int in 3:await physics_frame
 paused=true;var elapsed: float=actor.elapsed
 for i: int in 6:await process_frame
 assert(actor.elapsed==elapsed);paused=false
 var focus_actor: Actor=spawn(pool,Vector3(5,0,0))
 for i: int in 3:await physics_frame
 Engine.time_scale=.2;focus_actor.begin_death(Vector3(0,0,-1),PackedStringArray(["rifle"]))
 for i: int in 6:await physics_frame
 var focused: float=focus_actor.elapsed;Engine.time_scale=1.0
 assert(focused<.1 and focused>0)
 var flying: Actor=spawn(pool,Vector3(-8,0,0))
 for i: int in 3:await physics_frame
 flying.begin_death(Vector3(0,0,-1),PackedStringArray(["shotgun"]))
 for i: int in 30:await physics_frame
 var root_delta: Vector3=flying.position-Vector3(-8,0,0)
 var authored_delta: Vector3=flying.selected.root_at(flying.elapsed)
 var root_error: float=root_delta.distance_to(authored_delta)
 assert(root_error<.01, "Root motion recovered against its own ragdoll bodies")
 var strict_pool:=Pool.new();strict_pool.configure(settings);var locked: Array=[]
 for i: int in 6:locked.append(spawn(strict_pool,Vector3(float(i)*2.0-6,0,8)))
 for i: int in 3:await physics_frame
 for item: Actor in locked:item.begin_death(Vector3(1,0,0),PackedStringArray());item.allow_eviction=false
 assert(strict_pool.active.size()==6)
 var lite: Actor=spawn(strict_pool,Vector3(0,0,12))
 for i: int in 3:await physics_frame
 lite.begin_death(Vector3(1,0,0),PackedStringArray())
 assert(not lite.full_ragdoll and lite.physical.size()<=8 and strict_pool.active.size()==6)
 var shape_count: int=0
 for bone: PhysicalBone3D in lite.physical.values():shape_count+=bone.get_child_count()
 assert(shape_count==15)
 for i: int in 30:await physics_frame
 var before: Array[Transform3D]=lite.capture_pose();assert(lite.freeze_corpse());var after: Array[Transform3D]=lite.capture_pose();var delta: float=0.0
 for i: int in before.size():delta=maxf(delta,before[i].origin.distance_to(after[i].origin))
 assert(delta<.0001)
 assert(lite.lethal_events_received==1 and lite.handoff_count==1)
 var result: Dictionary={"passed":true,"self_collision_root_error_m":root_error,"pause_preserved":true,"focus_elapsed_six_ticks":focused,"full_budget":strict_pool.active.size(),"lite_bodies":lite.physical.size(),"lite_collision_shapes":shape_count,"freeze_pose_delta_m":delta,"authoritative_event_count":lite.lethal_events_received,"handoff_count":lite.handoff_count,"note":"No gameplay reward callbacks exist in this presentation fixture; live game integration is not claimed"}
 var file:=FileAccess.open("res://data/death/contracts_test_report.json",FileAccess.WRITE);file.store_string(JSON.stringify(result,"  "));file.close();print("CONTRACT_TEST_PASS ",JSON.stringify(result));quit()
