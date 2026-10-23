extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var config: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/ragdoll/settings.json"))
 var pool=preload("res://scripts/death/ragdoll_budget.gd").new();pool.configure(config)
 var actor=preload("res://scripts/ragdoll/anatomical_actor.gd").new();root.add_child(actor);actor.setup(config,pool)
 var bodies: Dictionary={};var proxies: Dictionary={};var overlaps: Array=[]
 for name: String in actor.physical:
  var bone: PhysicalBone3D=actor.physical[name]
  var rest: Transform3D=actor.skeleton.get_bone_global_rest(actor.skeleton.find_bone(name))*bone.body_offset
  var shape: Shape3D=bone.get_child(0).shape
  var proxy:=StaticBody3D.new();proxy.collision_layer=1048576;proxy.collision_mask=0;root.add_child(proxy);proxy.transform=rest
  var col:=CollisionShape3D.new();col.shape=shape;proxy.add_child(col);proxies[name]=proxy
  bodies[name]={"center_m":[rest.origin.x,rest.origin.y,rest.origin.z],"shape":shape.get_class(),"mass_kg":bone.mass,"parent":actor._parent_name(name)}
  if shape is BoxShape3D:bodies[name].size_m=[shape.size.x,shape.size.y,shape.size.z]
  else:bodies[name].radius_m=shape.radius;bodies[name].height_m=shape.height if shape is CapsuleShape3D else shape.radius*2.0
 for i: int in 2:await physics_frame
 for name: String in proxies:
  for other: String in proxies:
   if name>=other:continue
   var q:=PhysicsShapeQueryParameters3D.new();q.shape=proxies[name].get_child(0).shape;q.transform=proxies[name].global_transform;q.collision_mask=1048576;q.margin=0.0
   for excluded_name: String in proxies:
    if excluded_name!=other:q.exclude.append(proxies[excluded_name].get_rid())
   # Array-valued query properties return copies; assign the complete RID array.
   var excluded: Array[RID]=[]
   for excluded_name: String in proxies:
    if excluded_name!=other:excluded.append(proxies[excluded_name].get_rid())
   q.exclude=excluded
   var points: PackedVector3Array=actor.get_world_3d().direct_space_state.collide_shape(q,8);var depth: float=0.0
   for i: int in range(0,points.size()-1,2):depth=maxf(depth,points[i].distance_to(points[i+1]))
   if depth>.000001:overlaps.append({"a":name,"b":other,"overlap_m":depth,"neighbor":bodies[name].parent==other or bodies[other].parent==name})
 var settings=preload("res://scripts/death/death_settings.gd").new();settings.values=config
 assert(ResourceSaver.save(settings,"res://data/ragdoll/settings.tres")==OK)
 var file:=FileAccess.open("res://data/ragdoll/rest_geometry_report.json",FileAccess.WRITE);file.store_string(JSON.stringify({"bodies":bodies,"overlaps":overlaps,"method":"Jolt shape contacts in skeleton rest space; zero query margin"},"  "));file.close()
 print("REST_AUDIT bodies=",bodies.size()," overlaps=",overlaps.size());actor.free();quit()
