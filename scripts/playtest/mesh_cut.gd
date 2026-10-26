extends RefCounted
## Clip imported skinned triangles, preserving UVs, weights and clothing coverage.
## No gameplay collider or skeleton edits. All positions are mesh-local rest space.
static func vertex(arrays: Array,i: int) -> Dictionary:
 var bones:=PackedInt32Array();var weights:=PackedFloat32Array()
 for k: int in 4:
  bones.append(arrays[Mesh.ARRAY_BONES][i*4+k]);weights.append(arrays[Mesh.ARRAY_WEIGHTS][i*4+k])
 var tangent:=Plane(1,0,0,1)
 if arrays[Mesh.ARRAY_TANGENT]!=null:
  var t: PackedFloat32Array=arrays[Mesh.ARRAY_TANGENT];tangent=Plane(t[i*4],t[i*4+1],t[i*4+2],t[i*4+3])
 return {"p":arrays[Mesh.ARRAY_VERTEX][i],"n":arrays[Mesh.ARRAY_NORMAL][i],"uv":arrays[Mesh.ARRAY_TEX_UV][i],"color":arrays[Mesh.ARRAY_COLOR][i] if arrays[Mesh.ARRAY_COLOR]!=null else Color(0,0,0,1),"t":tangent,"bones":bones,"weights":weights}
static func interpolate(a: Dictionary,b: Dictionary,t: float) -> Dictionary:
 var merged: Dictionary={}
 for k: int in 4:
  merged[a.bones[k]]=float(merged.get(a.bones[k],0))+a.weights[k]*(1-t)
  merged[b.bones[k]]=float(merged.get(b.bones[k],0))+b.weights[k]*t
 var keys: Array=merged.keys();keys.sort_custom(func(x,y)->bool:return merged[x]>merged[y])
 var bones:=PackedInt32Array();var weights:=PackedFloat32Array();var total: float=0
 for k: int in 4:
  bones.append(keys[k] if k<keys.size() else 0);weights.append(float(merged[keys[k]]) if k<keys.size() else 0);total+=weights[k]
 for k: int in 4:weights[k]/=maxf(total,.0001)
 return {"p":a.p.lerp(b.p,t),"n":a.n.lerp(b.n,t).normalized(),"uv":a.uv.lerp(b.uv,t),"color":a.color.lerp(b.color,t),"t":Plane(a.t.normal.lerp(b.t.normal,t).normalized(),a.t.d),"bones":bones,"weights":weights}
static func polygon(poly: Array,normal: Vector3,distance: float,positive: bool,boundary: Array) -> Array:
 var result: Array=[]
 for i: int in poly.size():
  var a: Dictionary=poly[i];var b: Dictionary=poly[(i+1)%poly.size()]
  var da: float=normal.dot(a.p)-distance;var db: float=normal.dot(b.p)-distance
  var inside: bool=da>=0 if positive else da<=0
  var next_inside: bool=db>=0 if positive else db<=0
  if inside:result.append(a)
  if inside!=next_inside:
   var v: Dictionary=interpolate(a,b,da/(da-db));result.append(v);boundary.append(v)
 return result
static func emit(tool: SurfaceTool,poly: Array) -> void:
 for i: int in range(1,poly.size()-1):
  for v: Dictionary in [poly[0],poly[i],poly[i+1]]:
   tool.set_normal(v.n);tool.set_uv(v.uv);tool.set_color(v.color);tool.set_tangent(v.t);tool.set_bones(v.bones);tool.set_weights(v.weights);tool.add_vertex(v.p)
static func split(mesh: Mesh,normal: Vector3,distance: float,side: int) -> Dictionary:
 var kept:=SurfaceTool.new();var removed:=SurfaceTool.new();kept.begin(Mesh.PRIMITIVE_TRIANGLES);removed.begin(Mesh.PRIMITIVE_TRIANGLES)
 var boundary: Array=[];var keep_count: int=0;var remove_count: int=0
 for surface: int in mesh.get_surface_count():
  var arrays: Array=mesh.surface_get_arrays(surface);var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
  for index: int in range(0,indices.size(),3):
   var poly: Array=[vertex(arrays,indices[index]),vertex(arrays,indices[index+1]),vertex(arrays,indices[index+2])]
   var center: Vector3=(poly[0].p+poly[1].p+poly[2].p)/3
   if side!=0 and center.x*side<0:
    emit(kept,poly);keep_count+=1;continue
   var cut: Array=polygon(poly,normal,distance,true,boundary)
   var retain: Array=polygon(poly,normal,distance,false,[])
   if cut.size()>2:emit(removed,cut);remove_count+=cut.size()-2
   if retain.size()>2:emit(kept,retain);keep_count+=retain.size()-2
 var result: Dictionary={"boundary":boundary,"kept":null,"removed":null,"removed_triangles":remove_count}
 if keep_count>0:kept.index();result.kept=kept.commit()
 if remove_count>0:removed.index();result.removed=removed.commit()
 return result
static func bake(mesh: Mesh,skin: Skin,skeleton: Skeleton3D,frame: Transform3D) -> ArrayMesh:
 var transforms: Array[Transform3D]=[]
 for bind: int in skin.get_bind_count():
  var index: int=skeleton.find_bone(skin.get_bind_name(bind))
  transforms.append(frame.affine_inverse()*skeleton.global_transform*skeleton.get_bone_global_pose(index)*skin.get_bind_pose(bind))
 var arrays: Array=mesh.surface_get_arrays(0);var points: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX];var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL];var tangents: PackedFloat32Array=arrays[Mesh.ARRAY_TANGENT]
 for i: int in points.size():
  var p:=Vector3.ZERO;var n:=Vector3.ZERO;var tangent:=Vector3.ZERO
  for k: int in 4:
   var transform: Transform3D=transforms[arrays[Mesh.ARRAY_BONES][i*4+k]];var weight: float=arrays[Mesh.ARRAY_WEIGHTS][i*4+k]
   p+=(transform*points[i])*weight;n+=(transform.basis*normals[i])*weight
   if tangents.size()>0:tangent+=(transform.basis*Vector3(tangents[i*4],tangents[i*4+1],tangents[i*4+2]))*weight
  points[i]=p;normals[i]=n.normalized()
  if tangents.size()>0:
   tangent=tangent.normalized();tangents[i*4]=tangent.x;tangents[i*4+1]=tangent.y;tangents[i*4+2]=tangent.z
 arrays[Mesh.ARRAY_VERTEX]=points;arrays[Mesh.ARRAY_NORMAL]=normals;arrays[Mesh.ARRAY_TANGENT]=tangents;arrays[Mesh.ARRAY_BONES]=null;arrays[Mesh.ARRAY_WEIGHTS]=null
 var result:=ArrayMesh.new();result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays);return result
