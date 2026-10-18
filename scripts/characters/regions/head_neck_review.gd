extends Node3D
## Private manifest-driven region preview. No health, AI, damage, death or loot hooks.
## Do not connect this review assembly to live gameplay until the region is approved.
signal cosmetic_state_changed(previous: StringName, current: StringName)
var manifest: Dictionary
var folder: String
var current_state: StringName=&""
var current: Node3D
var skeleton: Skeleton3D
var meshes: Array[MeshInstance3D]=[]
var corrective_bindings: Array[Dictionary]=[]
var variant_index: int=0
var camera: Camera3D
var corrective_enabled: bool=true
var process_distance_m: float=15.0
var errors:=PackedStringArray()

func configure(manifest_path: String) -> bool:
 errors.clear()
 for method: String in ["get_bone_pose_rotation","get_bone_global_pose","get_bone_count"]:
  if not ClassDB.class_has_method("Skeleton3D",method):return _fail("Missing Skeleton3D API: "+method)
 if not ClassDB.class_has_method("MeshInstance3D","set_blend_shape_value"):return _fail("Missing blend shape API")
 var decoded: Variant=JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
 if not decoded is Dictionary:return _fail("Invalid manifest JSON")
 manifest=decoded as Dictionary;folder=manifest_path.get_base_dir()
 if manifest.get("schema")!=1 or manifest.get("region")!="head_neck":return _fail("Unsupported region manifest")
 process_distance_m=float(manifest.get("limits",{}).get("corrective_distance_m",15.0))
 return set_state(&"intact")

func _fail(message: String) -> bool:
 errors.append(message)
 return false

func set_state(next: StringName) -> bool:
 if not manifest.get("states",{}).has(String(next)):return _fail("Unknown cosmetic state")
 if next==current_state and current!=null:return true
 var entry: Dictionary=manifest.states[String(next)]
 var path: String=folder.path_join(str(entry.path))
 if str(entry.path)!=str(entry.path).get_file() or ".." in str(entry.path):return _fail("State path escapes manifest directory")
 var packed: PackedScene=load(path) as PackedScene
 if packed==null:return _fail("Missing scene: "+path)
 var replacement: Node3D=packed.instantiate() as Node3D
 var rigs: Array[Node]=replacement.find_children("*","Skeleton3D",true,false)
 if rigs.size()!=1:
  replacement.free();return _fail("Exactly one skeleton required")
 var next_rig: Skeleton3D=rigs[0] as Skeleton3D
 if next_rig.get_bone_count()!=manifest.bone_names.size():
  replacement.free();return _fail("Manifest bone count mismatch")
 for i: int in next_rig.get_bone_count():
  if next_rig.get_bone_name(i)!=str(manifest.bone_names[i]):
   replacement.free();return _fail("Manifest bone order mismatch")
 if current!=null:current.free()
 current=replacement;skeleton=next_rig;add_child(current)
 meshes.clear();corrective_bindings.clear()
 for node: Node in current.find_children("*","MeshInstance3D",true,false):
  var mesh: MeshInstance3D=node as MeshInstance3D
  meshes.append(mesh)
  if next==&"damaged" and mesh.mesh.get_surface_count()>0:
   var base: Material=mesh.get_active_material(0)
   if base!=null:
    var overlay:=ShaderMaterial.new()
    overlay.shader=preload("neck_bruise_review.gdshader")
    var copy: Material=base.duplicate() as Material
    copy.next_pass=overlay
    mesh.set_surface_override_material(0,copy)
  for definition: Dictionary in manifest.correctives:
   var index: int=mesh.find_blend_shape_by_name(str(definition.shape))
   if index<0:continue
   var coords: Array=definition.axis
   # Bone rotations are in bone-local coordinates; the glTF importer preserves
   # the local rotation axes with the bone's imported rest basis.
   corrective_bindings.append({"mesh":mesh,"index":index,"bone":skeleton.find_bone(str(definition.bone)),"axis":Vector3(float(coords[0]),float(coords[1]),float(coords[2])),"angle":deg_to_rad(float(definition.angle_degrees))})
  var closed_index: int=mesh.find_blend_shape_by_name("fractured_closed")
  if closed_index>=0:mesh.set_blend_shape_value(closed_index,1.0 if next==&"fractured_closed" else 0.0)
 # Markers live under bone attachments. Convert rest-world positions to each
 # attachment's bone-local coordinates so they follow an animated neck.
 for socket: Dictionary in manifest.sockets:
  var bone: int=skeleton.find_bone(str(socket.bone))
  if bone<0:continue
  var attachment:=BoneAttachment3D.new();attachment.bone_name=str(socket.bone);skeleton.add_child(attachment)
  var marker:=Marker3D.new();marker.name=str(socket.name);attachment.add_child(marker)
  var p: Array=socket.position;var d: Array=socket.outward
  var local_rest: Transform3D=skeleton.get_bone_global_rest(bone).affine_inverse()
  marker.position=local_rest*Vector3(float(p[0]),float(p[1]),float(p[2]))
  var direction: Vector3=(local_rest.basis*Vector3(float(d[0]),float(d[1]),float(d[2]))).normalized()
  marker.quaternion=Quaternion(Vector3.FORWARD,direction)
 var previous: StringName=current_state;current_state=next
 set_variant(variant_index)
 cosmetic_state_changed.emit(previous,current_state)
 return true

func set_variant(index: int) -> void:
 variant_index=clampi(index,0,2)
 for mesh: MeshInstance3D in meshes:
  var is_half: bool=String(mesh.name).contains("HN_head_v") or String(mesh.name).contains("HN_stump_v")
  if is_half:mesh.visible=String(mesh.name).ends_with("v"+str(variant_index))
  mesh.position=Vector3.ZERO
  if String(mesh.name).contains("HN_head_v"):
   if manifest.get("review_offsets",{}).has(String(current_state)):
    var offset: Array=manifest.review_offsets[String(current_state)]
    mesh.position=Vector3(float(offset[0]),float(offset[1]),float(offset[2]))

func set_review_pose(neck_angle_radians: float, axis: Vector3=Vector3.RIGHT) -> void:
 if skeleton==null:return
 skeleton.set_bone_pose_rotation(skeleton.find_bone("Neck"),Quaternion(axis,neck_angle_radians))
 update_correctives()

func update_correctives() -> void:
 if skeleton==null:return
 var near: bool=camera==null or camera.global_position.distance_squared_to(global_position)<process_distance_m*process_distance_m
 for binding: Dictionary in corrective_bindings:
  var weight: float=0.0
  if corrective_enabled and near:
   var rotation: Quaternion=skeleton.get_bone_pose_rotation(int(binding.bone)).normalized()
   if rotation.w<0:rotation=-rotation
   var vector:=Vector3(rotation.x,rotation.y,rotation.z)
   var signed_angle: float=2.0*atan2(vector.dot(binding.axis),rotation.w)
   weight=clampf(signed_angle/float(binding.angle),0.0,1.0)
  (binding.mesh as MeshInstance3D).set_blend_shape_value(int(binding.index),weight)

func _process(_delta: float) -> void:
 update_correctives()
