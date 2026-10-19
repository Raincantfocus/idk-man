extends RefCounted
## Review-only mesh replacement. Original imported resources are never mutated.
static func apply(model_root: Node3D, patch: Dictionary) -> Dictionary:
 var output: Dictionary={}
 for node: Node in model_root.find_children("*","MeshInstance3D",true,false):
  var mesh: MeshInstance3D=node as MeshInstance3D;var key: String=String(mesh.name)
  if not patch.meshes.has(key):continue
  var edit: Dictionary=patch.meshes[key];var arrays: Array=mesh.mesh.surface_get_arrays(0)
  var positions: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
  if edit.has("v"):
   assert(edit.v.size()==positions.size())
   for i: int in positions.size():positions[i]=Vector3(edit.v[i][0],edit.v[i][1],edit.v[i][2])
   arrays[Mesh.ARRAY_VERTEX]=positions
  if edit.has("w"):
   var weights:=PackedFloat32Array();var joints:=PackedInt32Array()
   for i: int in positions.size():
    assert(edit.w[i].size()==4 and edit.j[i].size()==4)
    for k: int in 4:weights.append(float(edit.w[i][k]));joints.append(int(edit.j[i][k]))
   arrays[Mesh.ARRAY_WEIGHTS]=weights;arrays[Mesh.ARRAY_BONES]=joints
  if edit.has("covered"):
   var colors:=PackedColorArray()
   for i: int in positions.size():colors.append(Color(float(edit.covered[i]),float(edit.zones[i])/31.0,0,1))
   arrays[Mesh.ARRAY_COLOR]=colors
  var result:=ArrayMesh.new();result.blend_shape_mode=Mesh.BLEND_SHAPE_MODE_NORMALIZED
  var shapes: Array[Array]=[]
  for name: String in edit.get("correctives",{}):
   result.add_blend_shape(name);var shape: Array=[];shape.resize(Mesh.ARRAY_MAX)
   var target:=PackedVector3Array();var delta: Array=edit.correctives[name]
   for i: int in positions.size():target.append(positions[i]+Vector3(delta[i][0],delta[i][1],delta[i][2]))
   shape[Mesh.ARRAY_VERTEX]=target;shape[Mesh.ARRAY_NORMAL]=arrays[Mesh.ARRAY_NORMAL];shape[Mesh.ARRAY_TANGENT]=arrays[Mesh.ARRAY_TANGENT];shapes.append(shape)
  result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays,shapes)
  result.surface_set_material(0,mesh.mesh.surface_get_material(0));mesh.mesh=result
  if edit.has("covered"):
   var material:=ShaderMaterial.new();material.shader=preload("body_visibility.gdshader");mesh.material_override=material
   mesh.set_instance_shader_parameter("reveal",0.0)
  output[key]=mesh
 return output
