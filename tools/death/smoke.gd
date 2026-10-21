extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var world:=Node3D.new();root.add_child(world)
 var floor:=StaticBody3D.new();floor.collision_layer=1;world.add_child(floor);floor.position.y=-.25
 var collider:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(20,.5,20);collider.shape=box;floor.add_child(collider)
 var settings: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/death/settings.json"))
 var pool=preload("res://scripts/death/ragdoll_budget.gd").new();pool.configure(settings)
 var actor=preload("res://scripts/death/death_actor.gd").new();world.add_child(actor);actor.setup(settings,pool)
 for i: int in 3:await physics_frame
 assert(actor.begin_death(Vector3(0,0,1),PackedStringArray(["shotgun"]),Vector3(0,2,12)))
 for i: int in 180:await physics_frame
 print("SMOKE ",JSON.stringify(actor.trace)," STATE ",actor.state," HEAD ",actor.points().Head)
 quit()
