extends Node
const Cut=preload("mesh_cut.gd")
var actor: Node
var service: Node
var definitions: Dictionary
var originals: Dictionary={}
var cuts: Dictionary={}
var caps: Array[Node]=[]
var pending: Dictionary={}
var alive: bool=true
var hit_id: int=0
var state:=preload("res://scripts/trauma/zone_trauma_state.gd").new()
var serial: int=0
static var tissue_materials: Dictionary={}
static var split_cache: Dictionary={}
static var cap_cache: Dictionary={}
static func load_cache() -> void:
 if split_cache.is_empty() and ResourceLoader.exists("res://data/playtest/gore_geometry.res"):
  var data: Resource=load("res://data/playtest/gore_geometry.res")
  split_cache=data.splits.duplicate();cap_cache=data.caps.duplicate()
 tissue("neck")
func setup(target: Node,runtime: Node,seed: int) -> void:
 actor=target;service=runtime;serial=seed
 definitions=JSON.parse_string(FileAccess.get_file_as_string("res://data/playtest/gore_cuts.json"))
 state.configure(service.zone_definitions,seed)
 for mesh: MeshInstance3D in actor.presentation.find_children("*","MeshInstance3D",true,false):originals[mesh]={"mesh":mesh.mesh,"visible":mesh.visible}
 actor.set_meta("gore_presenter",self)
 actor.child_entered_tree.connect(_corpse_child)
func region(point: Vector3,headshot: bool) -> String:
 if headshot:return "head"
 var best: String="";var distance: float=.24
 for key: String in definitions:
  var d: Dictionary=definitions[key];var bone: int=actor.skeleton.find_bone(d.bone)
  var p: Vector3=actor.skeleton.global_transform*actor.skeleton.get_bone_global_pose(bone).origin
  var tip_name: String="Head" if key=="head" else ("LeftHand" if key=="left_arm" else "RightHand" if key=="right_arm" else "LeftFoot" if key=="left_leg" else "RightFoot")
  var tip: Vector3=actor.skeleton.global_transform*actor.skeleton.get_bone_global_pose(actor.skeleton.find_bone(tip_name)).origin
  var closest: Vector3=Geometry3D.get_closest_point_to_segment(point,p,tip)
  var value: float=closest.distance_to(point)
  if value<distance:distance=value;best=key
 return best
func hit(amount: float,point: Vector3,headshot: bool,fatal: bool=false) -> void:
 var key: String=region(point,headshot)
 if key.is_empty() or cuts.has(key):return
 hit_id+=1
 var d: Dictionary=definitions[key]
 var weapon: StringName=&"shotgun" if service.game.player.weapon_index==1 else &"rifle"
 var direction: Vector3=(point-service.game.player.camera.global_position).normalized()
 state.apply_hit(hit_id,StringName(d.zone),amount,weapon,point.distance_to(service.game.player.global_position),amount,direction,Vector3.UP)
 if state.states.get(StringName(d.zone),0)==4:
  pending[key]=direction
  if fatal and not alive:sever(key,direction)
func on_death() -> void:
 alive=false
 for body: PhysicalBone3D in actor.physical.values():
  body.set_script(preload("corpse_hit.gd"));body.set("gore",self)
 for key: String in pending.keys():sever(key,pending[key])
static func tissue(region_name: String) -> ShaderMaterial:
 var folder: String="shared"
 if not tissue_materials.has(folder):
  var material:=ShaderMaterial.new();material.shader=preload("res://scripts/trauma/tissue_atlas.gdshader")
  for pair: Array in [["albedo_atlas","tissue_albedo.png"],["normal_atlas","tissue_normal.png"],["orm_atlas","tissue_orm.png"],["flow_atlas","tissue_flow.png"]]:material.set_shader_parameter(pair[0],load("res://assets/playtest_gore/caps/"+folder+"/"+pair[1]))
  tissue_materials[folder]=material
 return tissue_materials[folder]
func fitted_cap(kind: String,boundary: Array,normal: Vector3,underside: bool) -> ArrayMesh:
 var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/playtest_gore/caps/manifest.json"))
 var frame:=Basis(Quaternion(Vector3.UP,normal))
 var center:=Vector3.ZERO
 for v: Dictionary in boundary:center+=v.p
 center/=float(boundary.size())
 var cache_key: String=kind+str(normal)+str(center)+str(underside)
 if cap_cache.has(cache_key):return cap_cache[cache_key]
 var source: Node=load("res://assets/playtest_gore/caps/"+String(manifest.regions[kind])).instantiate()
 var radius:=Vector2.ZERO
 for v: Dictionary in boundary:
  var local: Vector3=frame.inverse()*(v.p-center);radius=radius.max(Vector2(absf(local.x),absf(local.z)))
 var source_radius:=Vector2.ZERO
 for mesh: MeshInstance3D in source.find_children("*","MeshInstance3D",true,false):
  for surface: int in mesh.mesh.get_surface_count():
   for p: Vector3 in mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:source_radius=source_radius.max(Vector2(absf(p.x),absf(p.z)))
 var tool:=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES)
 for mesh: MeshInstance3D in source.find_children("*","MeshInstance3D",true,false):
  for surface: int in mesh.mesh.get_surface_count():
   var arrays: Array=mesh.mesh.surface_get_arrays(surface)
   for i: int in arrays[Mesh.ARRAY_INDEX]:
    var local: Vector3=arrays[Mesh.ARRAY_VERTEX][i]
    local.x*=radius.x/maxf(source_radius.x,.001);local.z*=radius.y/maxf(source_radius.y,.001)
    if underside:local.y=-local.y
    var point: Vector3=center+frame*local
    var closest: Dictionary=boundary[0];var nearest: float=INF
    for v: Dictionary in boundary:
     var delta: Vector3=v.p-point;delta-=normal*delta.dot(normal)
     if delta.length_squared()<nearest:nearest=delta.length_squared();closest=v
    var n: Vector3=arrays[Mesh.ARRAY_NORMAL][i]
    if underside:n.y=-n.y
    tool.set_normal(frame*n);tool.set_uv(arrays[Mesh.ARRAY_TEX_UV][i]);tool.set_color(arrays[Mesh.ARRAY_COLOR][i] if arrays[Mesh.ARRAY_COLOR]!=null else Color.WHITE)
    tool.set_bones(closest.bones);tool.set_weights(closest.weights);tool.add_vertex(point)
 tool.index();tool.generate_tangents();var result: ArrayMesh=tool.commit();source.free();cap_cache[cache_key]=result;return result
func sever(key: String,direction: Vector3) -> bool:
 if alive or service.game.gore_level==0 or cuts.has(key) or cuts.size()>=4:return false
 var started: int=Time.get_ticks_usec()
 var owner_id: int=actor.get_instance_id()
 var gib:=preload("gib_lifetime.gd").new();gib.name="Cosmetic_"+key;gib.mass=float(definitions[key].mass);gib.collision_layer=0;gib.collision_mask=1;gib.continuous_cd=true;gib.linear_damp=.5;gib.angular_damp=1.5
 var lease: int=service.blood_budget.reserve(&"gibs",owner_id,1,Callable(gib,"queue_free"))
 if lease<0:gib.free();return false
 gib.ledger=service.blood_budget;gib.lease=lease
 service.game.add_child(gib);gib.add_to_group("gib");gib.add_to_group("transient");gib.process_mode=Node.PROCESS_MODE_PAUSABLE
 var d: Dictionary=definitions[key];var normal:=Vector3(d.normal[0],d.normal[1],d.normal[2])
 var frame: Transform3D=actor.skeleton.global_transform*actor.skeleton.get_bone_global_pose(actor.skeleton.find_bone(d.bone))
 gib.global_transform=frame
 var bound_points:=PackedVector3Array();var skin_boundary: Array=[];var source_skin: Skin
 for mesh: MeshInstance3D in originals:
  if not mesh.visible:continue
  var prior: Array=cuts.keys();prior.sort()
  var cache_key: String=String(mesh.name)+str(prior)+key
  if not split_cache.has(cache_key):
   if split_cache.size()>=32:split_cache.erase(split_cache.keys()[0])
   split_cache[cache_key]=Cut.split(mesh.mesh,normal,float(d.distance),int(d.side))
  var split: Dictionary=split_cache[cache_key]
  if split.removed==null:continue
  if String(mesh.name).begins_with("Body"):
   skin_boundary=split.boundary;source_skin=mesh.skin
  var piece:=MeshInstance3D.new();piece.mesh=Cut.bake(split.removed,mesh.skin,actor.skeleton,frame);piece.material_override=mesh.get_active_material(0);gib.add_child(piece)
  for p: Vector3 in piece.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:bound_points.append(p)
  if split.kept!=null:mesh.mesh=split.kept
  else:mesh.visible=false
 if bound_points.is_empty():service.blood_budget.release(lease);return false
 if not skin_boundary.is_empty():
  var cap:=MeshInstance3D.new();cap.mesh=fitted_cap(d.cap,skin_boundary,normal,false);actor.presentation.add_child(cap);cap.skin=source_skin;cap.skeleton=cap.get_path_to(actor.skeleton);cap.material_override=tissue(d.cap);caps.append(cap)
  var end:=MeshInstance3D.new();end.mesh=Cut.bake(fitted_cap(d.cap,skin_boundary,normal,true),source_skin,actor.skeleton,frame);end.material_override=tissue(d.cap);gib.add_child(end)
 var bounds:=AABB(bound_points[0],Vector3.ZERO)
 for p: Vector3 in bound_points:bounds=bounds.expand(p)
 var collider:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=bounds.size.max(Vector3.ONE*.03);collider.shape=shape;collider.position=bounds.get_center();gib.add_child(collider)
 gib.linear_velocity=direction.limit_length(1)*2+Vector3.UP
 gib.angular_velocity=Vector3(1,2,-1)
 service.wound_pool.remove_chain(actor,d.bone)
 cuts[key]=true
 actor.set_meta("last_cut_ms",float(Time.get_ticks_usec()-started)/1000.0)
 service.game.blood_burst(frame.origin,direction,12)
 service.log_once("new_sever:"+key,"INFO","New-model cosmetic sever: "+key+"; authored fitted cap, no solver/joint edits")
 return true
func restore() -> void:
 for mesh: MeshInstance3D in originals:
  if is_instance_valid(mesh):mesh.mesh=originals[mesh].mesh;mesh.visible=originals[mesh].visible
 for cap: Node in caps:
  if is_instance_valid(cap):cap.queue_free()
 caps.clear();cuts.clear();pending.clear();state.configure(service.zone_definitions,serial)

func _corpse_child(child: Node) -> void:
 if child is StaticBody3D:
  child.set_script(preload("frozen_corpse_hit.gd"));child.set("gore",self)
