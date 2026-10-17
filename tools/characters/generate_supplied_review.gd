extends SceneTree
## Private candidate Resources. Never approves source art or touches gameplay.
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var config: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://pipeline.json"))
 DirAccess.make_dir_recursive_absolute("res://shared_materials")
 var material_cache: Dictionary[String,Material]={}
 # Godot 4.6.3 ORMMaterial3D properties verified through ClassDB.
 assert(ClassDB.class_exists("ORMMaterial3D"))
 for group: String in ["fatigues","carrier","head"]:
  var material:=ORMMaterial3D.new()
  material.albedo_texture=load("res://%s_albedo.png"%group) as Texture2D
  material.orm_texture=load("res://%s_orm.png"%group) as Texture2D
  material.normal_enabled=true
  material.normal_texture=load("res://%s_normal.png"%group) as Texture2D
  material.metallic=1.0;material.roughness=1.0;material.ao_enabled=true
  var material_path: String="res://shared_materials/%s.tres"%group
  assert(ResourceSaver.save(material,material_path)==OK)
  material_cache[group]=load(material_path) as Material
  assert(material_cache[group].resource_path==material_path)
 DirAccess.make_dir_recursive_absolute("res://candidates")
 var report: Dictionary={"production_ready":false,"variants":[],"note":"Fitted candidate outfits, not five role kits. Missing helmet, masks, correctives and wound seams."}
 for shape: Dictionary in config.body_shapes:
  var definition:=ZLCharacterVariant.new()
  definition.variant_id=StringName("supplied_review_"+String(shape.id))
  definition.role=&"enforcer";definition.body_shape=StringName(shape.id)
  definition.shape_parameters=Vector3(shape.shoulders,shape.pelvis,shape.soft_tissue)
  definition.bone_map=load("res://humanoid_bone_map.tres") as BoneMap
  definition.required_parts=[&"fatigues",&"carrier",&"helmet"]
  definition.body_materials=[material_cache["head"]]
  for lod: int in 4:definition.body_lods.append(load("res://head_%s_lod%d.glb"%[shape.id,lod]) as PackedScene)
  for group: String in ["fatigues","carrier"]:
   var part:=ZLCharacterPart.new();part.part_id=StringName(group);part.body_shape=StringName(shape.id)
   part.source_url="user-upload:Makarov (shaded soldier).blend"
   part.license_id="User-purchased; redistribution terms unverified"
   part.materials=[material_cache[group]]
   for lod: int in 4:part.lod_scenes.append(load("res://%s_%s_lod%d.glb"%[group,shape.id,lod]) as PackedScene)
   definition.parts.append(part)
  var assembly:=ZLCharacterAssembly.new();root.add_child(assembly)
  assert(assembly.configure(definition,false),str(assembly.setup_errors))
  var costs: Array[Dictionary]=[]
  for lod: int in 4:
   var triangles: int=0
   var materials: Array[Material]=[]
   for node: Node in assembly.lod_roots[lod].find_children("*","MeshInstance3D",true,false):
    var mesh: MeshInstance3D=node as MeshInstance3D
    for surface: int in mesh.mesh.get_surface_count():
     var arrays: Array=mesh.mesh.surface_get_arrays(surface)
     triangles+=(arrays[Mesh.ARRAY_INDEX] as PackedInt32Array).size()/3
     var material: Material=mesh.get_active_material(surface)
     if not materials.has(material):materials.append(material)
   assert(assembly.lod_roots[lod].find_children("*","Skeleton3D",true,false).size()==1)
   costs.append({"lod":lod,"triangles":triangles,"materials":materials.size(),"bones":assembly.skeletons[lod].get_bone_count(),"triangle_budget_passed":triangles>=config.lod_soldier_triangles[lod][0] and triangles<=config.lod_soldier_triangles[lod][1]})
  assert(not assembly.configure(definition,true),"Unapproved art must fail production assembly")
  assert(assembly.get_child_count()==0,"Failed production assembly must clear previous review art")
  assembly.free()
  assert(ResourceSaver.save(definition,"res://candidates/"+String(shape.id)+".tres")==OK)
  report.variants.append({"definition":definition.to_data(),"costs":costs})
 var file:=FileAccess.open("res://candidate_report.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
 print("PRIVATE CANDIDATES: ",report.variants.size(),"; shared-rig and fail-closed production checks passed")
 quit()
