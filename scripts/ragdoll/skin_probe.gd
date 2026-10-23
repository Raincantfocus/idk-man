extends RefCounted
## Sparse CPU skin audit; not a proof for unsampled edges or GPU corrective output.
var vertices: PackedVector3Array
var bones: PackedInt32Array
var weights: PackedFloat32Array
var bind_poses: Array[Transform3D]=[]
var mapped: Array[int]=[]
var edges: Array=[]
func setup(actor: Node) -> void:
 var mesh: MeshInstance3D
 for candidate: Node in actor.find_children("*","MeshInstance3D",true,false):
  if candidate.name=="Body_LOD0":mesh=candidate;break
 assert(mesh!=null and mesh.skin!=null)
 var arrays: Array=mesh.mesh.surface_get_arrays(0);vertices=arrays[Mesh.ARRAY_VERTEX];bones=arrays[Mesh.ARRAY_BONES];weights=arrays[Mesh.ARRAY_WEIGHTS]
 for i: int in mesh.skin.get_bind_count():
  bind_poses.append(mesh.skin.get_bind_pose(i))
  var bone: int=mesh.skin.get_bind_bone(i)
  if bone<0:bone=actor.skeleton.find_bone(mesh.skin.get_bind_name(i))
  assert(bone>=0);mapped.append(bone)
 var excluded: Dictionary={}
 var patch: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/clipping/review_patch.json"))
 for delta: Array in patch.meshes.Body_LOD0.get("correctives",{}).values():
  for i: int in delta.size():
   if absf(float(delta[i][0]))+absf(float(delta[i][1]))+absf(float(delta[i][2]))>.000001:excluded[i]=true
 var rest: Array[Transform3D]=[]
 for i: int in actor.skeleton.get_bone_count():rest.append(actor.skeleton.get_bone_global_rest(i))
 var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX];var stride: int=maxi(3,int(indices.size()/600)*3)
 for i: int in range(0,indices.size()-2,stride):
  var a: int=indices[i];var b: int=indices[i+1]
  if excluded.has(a) or excluded.has(b):continue
  var length: float=skin(a,rest).distance_to(skin(b,rest))
  if length>.00001:edges.append({"a":a,"b":b,"rest":length})
func skin(vertex: int, pose: Array[Transform3D]) -> Vector3:
 var result:=Vector3.ZERO
 for slot: int in 4:
  var index: int=vertex*4+slot;var bind: int=bones[index]
  result+=(pose[mapped[bind]]*bind_poses[bind]*vertices[vertex])*weights[index]
 return result
func measure(actor: Node) -> float:
 var pose: Array[Transform3D]=actor.capture_pose();var peak: float=1.0
 for edge: Dictionary in edges:peak=maxf(peak,skin(edge.a,pose).distance_to(skin(edge.b,pose))/float(edge.rest))
 return peak
