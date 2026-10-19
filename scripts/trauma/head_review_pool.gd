extends Node3D
const Importer=preload("neck_cap_importer.gd")
const Budget=preload("cosmetic_budget.gd")
var importer: Importer
var budget: Budget
var config: Dictionary
var idle: Array[RigidBody3D]=[]
var active: Dictionary={}
func configure(source: Importer, ledger: Budget, settings: Dictionary) -> void:
 importer=source;budget=ledger;config=settings
func spawn_head(variant: int, owner_id: int, pose: Transform3D, direction: Vector3, spin: Vector3) -> RigidBody3D:
 if budget.gore_mode==0:return null
 var body: RigidBody3D
 for candidate: RigidBody3D in idle:
  if int(candidate.get_meta("variant"))==variant:body=candidate;break
 if body!=null:idle.erase(body)
 else:
  if idle.size()+active.size()>=int(config.budgets.gibs) and not idle.is_empty():idle.pop_front().free()
  body=importer.instantiate_head(variant,config,direction,spin);body.set_meta("variant",variant);add_child(body)
 var callback: Callable=func() -> void:recycle(body)
 var lease: int=budget.reserve(&"gibs",owner_id,1,callback)
 if lease<0:
  recycle(body);return null
 active[body.get_instance_id()]=lease
 body.global_transform=pose;body.freeze=false;body.sleeping=false;body.visible=true;body.collision_layer=8;body.collision_mask=1
 body.linear_velocity=Vector3.ZERO;body.angular_velocity=spin.limit_length(1)*float(config.max_angular_speed)
 body.apply_central_impulse(direction.limit_length(1)*float(config.max_launch_impulse_ns))
 return body
func recycle(body: RigidBody3D) -> void:
 if not is_instance_valid(body):return
 active.erase(body.get_instance_id());body.freeze=true;body.sleeping=true;body.linear_velocity=Vector3.ZERO;body.angular_velocity=Vector3.ZERO
 body.collision_layer=0;body.collision_mask=0;body.visible=false
 for node: Node in body.find_children("*","MeshInstance3D",true,false):
  var mesh: MeshInstance3D=node as MeshInstance3D
  for name: String in ["age","blood_fill","wet_front","dried_edge"]:mesh.set_instance_shader_parameter(name,0.0)
 if not idle.has(body):idle.append(body)
func spawn_head_pop(owner_id: int, pose: Transform3D, direction: Vector3, cosmetic_seed: int) -> Array[RigidBody3D]:
 var result: Array[RigidBody3D]=[]
 if budget.gore_mode==0:return result
 var rng:=RandomNumberGenerator.new();rng.seed=cosmetic_seed
 for index: int in 4:
  var body: RigidBody3D
  for candidate: RigidBody3D in idle:
   if int(candidate.get_meta("variant"))==100+index:body=candidate;break
  if body!=null:idle.erase(body)
  else:
   if idle.size()+active.size()>=int(config.budgets.gibs) and not idle.is_empty():idle.pop_front().free()
   body=importer.instantiate_fragment(index,config);body.set_meta("variant",100+index);add_child(body)
  var lease: int=budget.reserve(&"gibs",owner_id,1,func() -> void:recycle(body))
  if lease<0:recycle(body);continue
  active[body.get_instance_id()]=lease;body.global_transform=pose;body.freeze=false;body.sleeping=false;body.visible=true;body.collision_layer=8;body.collision_mask=1
  var spread:=Vector3(rng.randf_range(-.2,.2),rng.randf_range(0,.2),rng.randf_range(-.2,.2))
  body.linear_velocity=Vector3.ZERO;body.angular_velocity=spread.normalized()*float(config.max_angular_speed)
  body.apply_central_impulse((direction+spread).limit_length(1)*float(config.max_launch_impulse_ns)/4)
  result.append(body)
 return result
