extends Node3D
class_name ZLCharacterAssembly
## Asset review assembly only. No gameplay controller or procedural animation.
var variant: ZLCharacterVariant
var lod_roots: Array[Node3D] = []
var skeletons: Array[Skeleton3D] = []
var visible_lod: int = 0
var setup_errors := PackedStringArray()
var material_cache: Dictionary[Material,Material] = {}

func configure(definition: ZLCharacterVariant, require_production: bool = true) -> bool:
 setup_errors.clear()
 if definition==null:
  setup_errors.append("Variant missing")
  return false
 if require_production:
  setup_errors=definition.blockers()
  if not setup_errors.is_empty(): return false
 if definition.body_lods.size()!=4:
  setup_errors.append("Four body LOD scenes required")
  return false
 for child: Node in get_children(): child.free()
 lod_roots.clear()
 skeletons.clear()
 material_cache.clear()
 variant=definition
 for lod: int in 4:
  var branch := Node3D.new()
  branch.name="LOD"+str(lod)
  add_child(branch)
  lod_roots.append(branch)
  var body: Node3D = definition.body_lods[lod].instantiate() as Node3D
  branch.add_child(body)
  var found: Array[Node] = body.find_children("*","Skeleton3D",true,false)
  if found.size()!=1:
   return _fail("Body must have exactly one skeleton")
  var skeleton: Skeleton3D = found[0] as Skeleton3D
  skeletons.append(skeleton)
  for part: ZLCharacterPart in definition.parts:
   if part.body_shape!=definition.body_shape or part.lod_scenes.size()!=4:
    return _fail("Part fit/LOD mismatch: "+String(part.part_id))
   if not _safe_state(part.lod_scenes[lod].get_state()):
    return _fail("Cosmetic scene contains a script or collision node: "+String(part.part_id))
   var donor: Node3D = part.lod_scenes[lod].instantiate() as Node3D
   if not donor.find_children("*","CollisionObject3D",true,false).is_empty() or donor is CollisionObject3D:
    donor.free()
    return _fail("Cosmetic part contains collision: "+String(part.part_id))
   _apply_materials(donor,part)
   if not part.socket_bone.is_empty():
    if skeleton.find_bone(String(part.socket_bone))<0:
     donor.free()
     return _fail("Socket bone missing")
    var attachment := BoneAttachment3D.new()
    attachment.bone_name=String(part.socket_bone)
    skeleton.add_child(attachment)
    attachment.add_child(donor)
    donor.transform=part.socket_transform
   else:
    branch.add_child(donor)
    var rigs: Array[Node] = donor.find_children("*","Skeleton3D",true,false)
    if rigs.size()!=1 or not _same_rest(skeleton,rigs[0] as Skeleton3D):
     donor.free()
     return _fail("Skinned part rest skeleton mismatch: "+String(part.part_id))
    for node: Node in donor.find_children("*","MeshInstance3D",true,false):
     var mesh: MeshInstance3D = node as MeshInstance3D
     mesh.reparent(branch,true)
     mesh.skeleton=mesh.get_path_to(skeleton)
    donor.free()
  var materials: Array[Material] = []
  for node: Node in branch.find_children("*","MeshInstance3D",true,false):
   var mesh: MeshInstance3D=node as MeshInstance3D
   for surface: int in mesh.mesh.get_surface_count():
    var material: Material=mesh.get_active_material(surface)
    if not materials.has(material): materials.append(material)
  if materials.size()>3: return _fail("Assembly exceeds three material resources")
 set_lod(0)
 return true

func _same_rest(a: Skeleton3D,b: Skeleton3D) -> bool:
 if a.get_bone_count()!=b.get_bone_count(): return false
 for i: int in a.get_bone_count():
  if a.get_bone_name(i)!=b.get_bone_name(i): return false
  if not a.get_bone_rest(i).is_equal_approx(b.get_bone_rest(i)): return false
 return true

func set_lod(index: int) -> void:
 visible_lod=clampi(index,0,lod_roots.size()-1)
 for i: int in lod_roots.size(): lod_roots[i].visible=i==visible_lod

func update_distance(distance_m: float) -> void:
 if variant==null or variant.lod_ranges.size()!=4: return
 var next: int=visible_lod
 while next<3 and distance_m>variant.lod_ranges[next+1]+variant.lod_margin: next+=1
 while next>0 and distance_m<variant.lod_ranges[next]-variant.lod_margin: next-=1
 if next!=visible_lod: set_lod(next)

func _apply_materials(root: Node3D,part: ZLCharacterPart) -> void:
 for node: Node in root.find_children("*","MeshInstance3D",true,false):
  var mesh: MeshInstance3D=node as MeshInstance3D
  for i: int in mini(mesh.mesh.get_surface_count(),part.materials.size()):
   var source: Material=part.materials[i]
   if not material_cache.has(source):
    var material: Material=source
    if material is ShaderMaterial:
     var shader_material: ShaderMaterial=material.duplicate() as ShaderMaterial
     if shader_material.shader==preload("res://scripts/characters/camo_pbr.gdshader"):
      shader_material.set_shader_parameter("primary_color",variant.camo_primary)
      shader_material.set_shader_parameter("secondary_color",variant.camo_secondary)
      shader_material.set_shader_parameter("tertiary_color",variant.camo_tertiary)
     material=shader_material
    material_cache[source]=material
   mesh.set_surface_override_material(i,material_cache[source])

func _fail(message: String) -> bool:
 setup_errors.append(message)
 for child: Node in get_children(): child.free()
 lod_roots.clear()
 skeletons.clear()
 material_cache.clear()
 variant=null
 return false

func _safe_state(state: SceneState) -> bool:
 var base: SceneState=state.get_base_scene_state()
 if base!=null and not _safe_state(base): return false
 for i: int in state.get_node_count():
  var type: StringName=state.get_node_type(i)
  if type==&"CollisionObject3D" or (type!=&"" and ClassDB.is_parent_class(type,&"CollisionObject3D")): return false
  for j: int in state.get_node_property_count(i):
   if state.get_node_property_name(i,j)==&"script" and state.get_node_property_value(i,j)!=null: return false
  var nested: PackedScene=state.get_node_instance(i)
  if nested!=null and not _safe_state(nested.get_state()): return false
 return true
