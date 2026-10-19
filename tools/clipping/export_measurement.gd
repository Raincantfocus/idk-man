extends SceneTree
## Read-only export of the actual imported meshes, skin binds and authored poses.
func vector(v: Vector3) -> Array:return [v.x,v.y,v.z]
func matrix(t: Transform3D) -> Array:
 return [t.basis.x.x,t.basis.y.x,t.basis.z.x,t.origin.x,t.basis.x.y,t.basis.y.y,t.basis.z.y,t.origin.y,t.basis.x.z,t.basis.y.z,t.basis.z.z,t.origin.z]
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var viewer: Node=(load("res://baseline_review.tscn" if FileAccess.file_exists("res://baseline_review.tscn") else "res://review.tscn") as PackedScene).instantiate();root.add_child(viewer);viewer.set_process(false)
 var sk: Skeleton3D=viewer.skeleton
 var data: Dictionary={"engine":Engine.get_version_info().string,"bones":[],"bone_parents":[],"rests":[],"meshes":[],"clips":[],"role":"enforcer_review_kit","body":"standard","sampling":"every third 60 Hz frame, endpoints, min/max angle and XYZ Euler excursion of every joint"}
 for i: int in sk.get_bone_count():data.bones.append(sk.get_bone_name(i));data.bone_parents.append(sk.get_bone_parent(i));data.rests.append(matrix(sk.get_bone_global_rest(i)))
 for node: Node in viewer.model_root.find_children("*","MeshInstance3D",true,false):
  var mesh: MeshInstance3D=node as MeshInstance3D;assert(mesh.mesh.get_surface_count()==1)
  var arrays: Array=mesh.mesh.surface_get_arrays(0);var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX];var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
  var record: Dictionary={"name":String(mesh.name),"vertices":[],"normals":[],"indices":Array(arrays[Mesh.ARRAY_INDEX]),"weights":Array(arrays[Mesh.ARRAY_WEIGHTS]),"joints":Array(arrays[Mesh.ARRAY_BONES]),"binds":[],"bind_bones":[]}
  for v: Vector3 in vertices:record.vertices.append(vector(v))
  for v: Vector3 in normals:record.normals.append(vector(v))
  for bind: int in mesh.skin.get_bind_count():
   record.binds.append(matrix(mesh.skin.get_bind_pose(bind)))
   var name: StringName=mesh.skin.get_bind_name(bind)
   record.bind_bones.append(sk.find_bone(String(name)) if name!=&"" else mesh.skin.get_bind_bone(bind))
  data.meshes.append(record)
 var library: AnimationLibrary=viewer.controller.player.get_animation_library(&"")
 for clip: StringName in library.get_animation_list():
  viewer.controller.preview_clip(clip);var animation: Animation=library.get_animation(clip)
  var end: int=int(ceil(animation.length*60.0));var samples: Dictionary={0:true,end:true};var all_poses: Array=[];var extremes: Dictionary={}
  for frame: int in end+1:
   viewer.controller.player.seek(minf(frame/60.0,animation.length),true);sk.force_update_all_bone_transforms()
   var pose: Array=[]
   for bone: int in sk.get_bone_count():
    pose.append(matrix(sk.get_bone_global_pose(bone)))
    var delta: Basis=sk.get_bone_rest(bone).basis.inverse()*sk.get_bone_pose(bone).basis
    var euler: Vector3=delta.get_euler();var values: Array=[euler.x,euler.y,euler.z,delta.get_rotation_quaternion().get_angle()]
    for axis: int in 4:
     var key: String=str(bone)+":"+str(axis);var value: float=values[axis]
     if not extremes.has(key):extremes[key]=[value,value,frame,frame]
     if value<float(extremes[key][0]):extremes[key][0]=value;extremes[key][2]=frame
     if value>float(extremes[key][1]):extremes[key][1]=value;extremes[key][3]=frame
   all_poses.append(pose)
   if frame%3==0:samples[frame]=true
  for entry: Array in extremes.values():samples[int(entry[2])]=true;samples[int(entry[3])]=true
  var frames: Array=samples.keys();frames.sort();var rows: Array=[]
  for frame: int in frames:rows.append({"frame":frame,"time":minf(frame/60.0,animation.length),"bones":all_poses[frame]})
  data.clips.append({"name":String(clip),"duration":animation.length,"frame_count":end+1,"samples":rows,"joint_extremes":extremes})
  print("MEASURE_SAMPLE ",clip," ",rows.size(),"/",end+1)
 var path: String=OS.get_cmdline_user_args()[0]
 var file:=FileAccess.open(path,FileAccess.WRITE);assert(file!=null);file.store_string(JSON.stringify(data));file.close();viewer.free();print("EXPORTED_MEASUREMENT ",path);quit()
