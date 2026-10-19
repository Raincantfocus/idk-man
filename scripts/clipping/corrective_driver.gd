extends RefCounted
## Invoke after authored animation evaluation. No gameplay callbacks.
var target: Skeleton3D
var meshes: Dictionary
var rules: Array
var near_distance: float=8.0
var active: bool=false
func configure(skeleton: Skeleton3D, patched_meshes: Dictionary, patch: Dictionary) -> void:
 target=skeleton;meshes=patched_meshes;rules=patch.get("corrective_rules",[]);near_distance=float(patch.get("corrective_near_distance_m",8.0))
func advance(camera_distance: float) -> void:
 if camera_distance>near_distance:
  if active:
   for mesh: MeshInstance3D in meshes.values():
    for rule: Dictionary in rules:mesh.set_blend_shape_value(mesh.find_blend_shape_by_name(StringName(rule.name)),0.0)
  active=false
  return
 active=true
 for rule: Dictionary in rules:
  var bone: int=target.find_bone(String(rule.bone));assert(bone>=0)
  var rotation: Quaternion=target.get_bone_rest(bone).basis.get_rotation_quaternion().inverse()*target.get_bone_pose_rotation(bone)
  var angle: float
  if rule.axis=="yaw":
   var basis:=Basis(rotation);angle=absf(atan2(basis.z.x,basis.z.z))
  else:angle=2.0*acos(clampf(absf(rotation.w),0.0,1.0))
  var value: float=0.0
  if camera_distance<=near_distance:
   var t: float=clampf((rad_to_deg(angle)-float(rule.start_degrees))/(float(rule.full_degrees)-float(rule.start_degrees)),0.0,1.0)
   value=t*t*(3.0-2.0*t)
  for mesh: MeshInstance3D in meshes.values():
   var shape: int=mesh.find_blend_shape_by_name(StringName(rule.name));assert(shape>=0)
   mesh.set_blend_shape_value(shape,value)
