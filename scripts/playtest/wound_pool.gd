extends Node
## Cosmetic FIFO pool. Ray queries return CollisionObject3D, never Skeleton3D;
## the caller resolves the presentation skeleton from that collision owner.
var config: Dictionary
var slots: Array[Dictionary]=[]
var serial: int=0
var projected: bool=false
var material: ShaderMaterial
var connected: Dictionary={}
var surface_cache: Dictionary={}
var refinement_frame: int=-1
var refinements: int=0
func _ready() -> void:
 config=JSON.parse_string(FileAccess.get_file_as_string("res://data/playtest/wounds.json"))
 projected=RenderingServer.get_current_rendering_method()!="gl_compatibility"
 material=ShaderMaterial.new();material.shader=preload("wound_surface.gdshader")
 for channel: String in ["albedo","normal","orm","height"]:
  material.set_shader_parameter(channel+"_map",load("res://assets/wounds/"+channel+".png"))
 material.set_shader_parameter("parallax_depth",config.parallax_depth_uv)
 material.set_shader_parameter("parallax_steps",int(config.parallax_steps))
 for i: int in int(config.global_pool):
  var socket:=BoneAttachment3D.new();socket.name="WoundSocket";add_child(socket)
  var visual: Node3D
  if projected:
   var decal:=Decal.new();decal.size=Vector3(config.diameter_m,config.projection_depth_m,config.diameter_m)
   decal.texture_albedo=load("res://assets/wounds/albedo.png")
   decal.texture_normal=load("res://assets/wounds/normal.png")
   decal.texture_orm=load("res://assets/wounds/orm.png")
   decal.cull_mask=1 << 19
   decal.normal_fade=.45;decal.upper_fade=.2;decal.lower_fade=.2
   decal.distance_fade_enabled=true;decal.distance_fade_begin=config.distance_fade_begin_m;decal.distance_fade_length=config.distance_fade_length_m
   visual=decal
  else:
   var patch:=MeshInstance3D.new();var quad:=QuadMesh.new();quad.size=Vector2.ONE*float(config.diameter_m);patch.mesh=quad;patch.material_override=material;patch.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
   patch.visibility_range_end=float(config.distance_fade_begin_m)+float(config.distance_fade_length_m)
   visual=patch
  socket.add_child(visual);visual.hide()
  slots.append({"socket":socket,"visual":visual,"owner":0,"stamp":0,"bone":-1})
func release(index: int) -> void:
 var slot: Dictionary=slots[index]
 slot.visual.hide();slot.owner=0;slot.bone=-1
 if slot.socket.get_parent()!=self:slot.socket.reparent(self,false)
func release_owner(owner_id: int) -> void:
 var actor: Object=instance_from_id(owner_id)
 if is_instance_valid(actor) and actor.get_meta("wound_reparent",false):return
 for i: int in slots.size():
  if slots[i].owner==owner_id:release(i)
 connected.erase(owner_id)
func clear() -> void:
 surface_cache.clear()
 for i: int in slots.size():
  if slots[i].owner!=0:release(i)
func remove_chain(actor: Node,bone_name: String) -> void:
 var root_bone: int=actor.skeleton.find_bone(bone_name)
 for i: int in slots.size():
  if slots[i].owner!=actor.get_instance_id():continue
  var bone: int=slots[i].bone
  while bone>=0:
   if bone==root_bone:release(i);break
   bone=actor.skeleton.get_bone_parent(bone)
 surface_cache.clear()
func surface_hit(actor: Node,point: Vector3,normal: Vector3,direction: Vector3) -> Dictionary:
 # Refine the gameplay capsule/bone collider hit against actual posed visible triangles.
 # Native CPU skin baking and TriangleMesh BVH; cache only for this physics frame.
 var frame: int=Engine.get_physics_frames()
 var cache: Dictionary=surface_cache
 if refinement_frame!=frame:refinement_frame=frame;refinements=0
 if cache.get("frame",-1)!=frame or cache.get("owner",0)!=actor.get_instance_id():
  if refinements>=int(config.max_surface_refinements_per_frame):return {}
  refinements+=1
  cache={"frame":frame,"owner":actor.get_instance_id(),"meshes":[]}
  for mesh: MeshInstance3D in actor.presentation.find_children("*","MeshInstance3D",true,false):
   if not mesh.visible or mesh.mesh==null:continue
   var baked: Mesh=mesh.mesh
   if mesh.skin!=null:
    if DisplayServer.get_name()=="headless":baked=preload("mesh_cut.gd").bake(mesh.mesh,mesh.skin,actor.skeleton,mesh.global_transform)
    else:baked=mesh.bake_mesh_from_current_skeleton_pose()
   if baked!=null:cache.meshes.append({"tree":baked.generate_triangle_mesh(),"transform":mesh.global_transform})
  surface_cache=cache
 var closest: Dictionary={};var distance: float=INF
 var ray_direction: Vector3=direction.normalized() if direction.length_squared()>.001 else -normal.normalized()
 var start: Vector3=point-ray_direction*.65;var end: Vector3=point+ray_direction*.9
 for entry: Dictionary in cache.meshes:
  var inverse: Transform3D=entry.transform.affine_inverse()
  var hit: Dictionary=entry.tree.intersect_segment(inverse*start,inverse*end)
  if hit.is_empty():continue
  var world: Vector3=entry.transform*hit.position
  var d: float=start.distance_squared_to(world)
  if d<distance:
   distance=d;closest={"point":world,"normal":(entry.transform.basis.inverse().transposed()*hit.normal).normalized()}
 return closest
func add_wound(actor: Node,point: Vector3,normal: Vector3,direction: Vector3=Vector3.ZERO) -> int:
 var started: int=Time.get_ticks_usec()
 var refined: Dictionary=surface_hit(actor,point,normal,direction)
 # Never place a floating patch if the cosmetic ray does not reach visible geometry.
 if refined.is_empty():return -1
 point=refined.point;normal=refined.normal
 var skeleton: Skeleton3D=actor.skeleton
 var owner_id: int=actor.get_instance_id()
 if not connected.has(owner_id):
  actor.tree_exiting.connect(release_owner.bind(owner_id));connected[owner_id]=true
  for mesh: MeshInstance3D in actor.presentation.find_children("*","MeshInstance3D",true,false):mesh.layers|=1 << 19
 var bone: int=-1;var nearest: float=INF
 # Choose the closest bone segment, not just its origin (important for forearms/shins).
 for b: int in skeleton.get_bone_count():
  var name_lower: String=skeleton.get_bone_name(b).to_lower()
  if "finger" in name_lower or "thumb" in name_lower or "index" in name_lower or "middle" in name_lower or "ring" in name_lower or "little" in name_lower:continue
  var start: Vector3=(skeleton.global_transform*skeleton.get_bone_global_pose(b)).origin
  var origin_distance: float=point.distance_squared_to(start)
  if origin_distance<=nearest:nearest=origin_distance;bone=b
  for child: int in skeleton.get_bone_children(b):
   var end: Vector3=(skeleton.global_transform*skeleton.get_bone_global_pose(child)).origin
   var d: float=point.distance_squared_to(Geometry3D.get_closest_point_to_segment(point,start,end))
   if d<nearest:nearest=d;bone=b
 if bone<0:return -1
 var owned: Array[int]=[];var free_index: int=-1;var oldest: int=0
 for i: int in slots.size():
  if slots[i].owner==owner_id:owned.append(i)
  if slots[i].owner==0 and free_index<0:free_index=i
  if slots[i].stamp<slots[oldest].stamp:oldest=i
 var index: int=free_index if free_index>=0 else oldest
 if owned.size()>=int(config.per_character):
  index=owned[0]
  for i: int in owned:
   if slots[i].stamp<slots[index].stamp:index=i
 release(index)
 var slot: Dictionary=slots[index];var socket: BoneAttachment3D=slot.socket
 socket.reparent(skeleton,false);socket.bone_idx=bone
 # Explicit captured bone pose avoids a one-frame attachment transform delay.
 socket.transform=skeleton.get_bone_global_pose(bone)
 var n: Vector3=normal.normalized() if normal.length_squared()>.001 else Vector3.FORWARD
 var tangent: Vector3=n.cross(Vector3.UP if absf(n.dot(Vector3.UP))<.95 else Vector3.RIGHT).normalized()
 var basis: Basis=Basis(tangent,n,tangent.cross(n)) if projected else Basis(tangent,n.cross(tangent),n)
 var world:=Transform3D(basis,point+(Vector3.ZERO if projected else n*float(config.surface_offset_m)))
 slot.visual.transform=(skeleton.global_transform*skeleton.get_bone_global_pose(bone)).affine_inverse()*world
 serial+=1;slot.owner=owner_id;slot.stamp=serial;slot.bone=bone;slot.visual.show()
 actor.set_meta("last_wound_ms",float(Time.get_ticks_usec()-started)/1000.0)
 return index

func add_from_raycast(ray: RayCast3D,actor: Node) -> int:
 # Caller supplies the character presentation owner; Skeleton3D itself is not a collider.
 if not ray.is_colliding():return -1
 return add_wound(actor,ray.get_collision_point(),ray.get_collision_normal(),ray.global_basis*ray.target_position)
