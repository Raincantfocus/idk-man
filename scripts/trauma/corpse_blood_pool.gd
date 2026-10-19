extends Node3D
## Forward+ uses native Decal; Compatibility uses a normal-aligned surface mesh.
## Caller supplies a traced surface point and receiver mask. Projection is 3 mm.
const Budget=preload("cosmetic_budget.gd")
var ledger: Budget
var free_nodes: Array[Node3D]=[]
var active: Array[Dictionary]=[]
var albedo: Texture2D
var normal: Texture2D
var wet_orm: Texture2D
var dry_orm: Texture2D
var shared_surface: ShaderMaterial
func setup(budget: Budget, pigment: Texture2D, normal_map: Texture2D, wet: Texture2D, dry: Texture2D) -> void:
 ledger=budget;albedo=pigment;normal=normal_map;wet_orm=wet;dry_orm=dry
 shared_surface=ShaderMaterial.new();shared_surface.shader=preload("blood_pool.gdshader");shared_surface.set_shader_parameter("pigment",albedo)
func add_pool(owner_id: int, point: Vector3, surface_normal: Vector3, receiver_mask: int) -> bool:
 if ledger.gore_mode==0 or receiver_mask==0 or surface_normal.is_zero_approx():return false
 var node: Node3D=free_nodes.pop_back() if not free_nodes.is_empty() else Node3D.new()
 if node.get_parent()==null:
  add_child(node)
  if RenderingServer.get_current_rendering_method()=="gl_compatibility":
   var surface:=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=Vector2.ONE;surface.mesh=plane;surface.material_override=shared_surface;node.add_child(surface)
  else:
   var decal:=Decal.new();decal.texture_albedo=albedo;decal.texture_normal=normal;decal.size=Vector3(1,.003,1);node.add_child(decal)
 var reset: Callable=func() -> void:
  node.visible=false
  active=active.filter(func(e: Dictionary) -> bool:return e.node!=node)
  if not free_nodes.has(node):free_nodes.append(node)
 var lease: int=ledger.reserve(&"decals",owner_id,1,reset,.5)
 if lease<0:reset.call();return false
 node.visible=true;node.global_position=point+surface_normal.normalized()*.0005;node.quaternion=Quaternion(Vector3.UP,surface_normal.normalized());node.scale=Vector3(.02,1,.02)
 var child: Node=node.get_child(0)
 if child is Decal:
  (child as Decal).cull_mask=receiver_mask;(child as Decal).texture_orm=wet_orm;(child as Decal).modulate=Color.WHITE
 else:(child as MeshInstance3D).set_instance_shader_parameter("pool_age",0.0)
 active.append({"node":node,"age":0.0,"lease":lease});return true
func advance(world_delta: float) -> void:
 if world_delta<=0:return
 for entry: Dictionary in active:
  entry.age=float(entry.age)+world_delta
  var node: Node3D=entry.node;var growth: float=lerpf(.02,.32,clampf(float(entry.age)/4.0,0,1));node.scale=Vector3(growth,1,growth*.8)
  var child: Node=node.get_child(0)
  if child is Decal:
   (child as Decal).modulate=Color.WHITE.lerp(Color(.42,.27,.25,1),clampf(float(entry.age)/60.0,0,1));(child as Decal).texture_orm=dry_orm if float(entry.age)>30 else wet_orm
  else:(child as MeshInstance3D).set_instance_shader_parameter("pool_age",float(entry.age))
