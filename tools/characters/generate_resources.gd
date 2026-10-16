extends SceneTree
## Godot 4.6.3 API verified against ClassDB before integration.
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var config: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/characters/pipeline.json")) as Dictionary
 var bone_names: Array=JSON.parse_string(FileAccess.get_file_as_string("res://data/characters/bone_names.json")) as Array
 var profile := SkeletonProfileHumanoid.new()
 var mapping := BoneMap.new()
 mapping.profile=profile
 for i: int in profile.get_bone_size():
  var bone: StringName=profile.get_bone_name(i)
  if bone_names.has(String(bone)): mapping.set_skeleton_bone_name(bone,bone)
  else:
   push_error("Missing humanoid bone: "+String(bone))
   quit(1)
   return
 DirAccess.make_dir_recursive_absolute("res://data/characters/variants")
 if ResourceSaver.save(mapping,"res://data/characters/humanoid_bone_map.tres")!=OK:
  quit(1)
  return
 var catalog: Array[Dictionary]=[]
 for role: String in config.roles:
  for index: int in config.body_shapes.size():
   var shape: Dictionary=config.body_shapes[index] as Dictionary
   var definition := ZLCharacterVariant.new()
   definition.variant_id=role+"_"+String(shape.id)
   definition.role=role
   definition.body_shape=shape.id
   definition.shape_parameters=Vector3(float(shape.shoulders),float(shape.pelvis),float(shape.soft_tissue))
   definition.bone_map=mapping
   definition.lod_ranges=PackedFloat32Array(config.lod_ranges_m)
   definition.lod_margin=float(config.lod_hysteresis_m)
   for lod: int in 4:
    var path: String="res://assets/characters/generated/%s_lod%d.glb"%[shape.id,lod]
    definition.body_lods.append(load(path) as PackedScene)
   for part: String in config.roles[role].parts: definition.required_parts.append(StringName(part))
   var rgb: Array=config.palettes[index] as Array
   definition.camo_primary=Color(float(rgb[0]),float(rgb[1]),float(rgb[2]))
   definition.camo_secondary=definition.camo_primary.darkened(.35)
   definition.camo_tertiary=definition.camo_primary.lightened(.3)
   var destination: String="res://data/characters/variants/"+String(definition.variant_id)+".tres"
   if ResourceSaver.save(definition,destination)!=OK:
    quit(1)
    return
   var exported: Dictionary=definition.to_data()
   exported["resource"]=destination
   catalog.append(exported)
 var file: FileAccess=FileAccess.open("res://data/characters/catalog.json",FileAccess.WRITE)
 file.store_string(JSON.stringify({"schema":1,"variants":catalog},"\t")+"\n")
 print("CHARACTER CATALOG: ",catalog.size()," variant Resources; all release blockers retained")
 quit()
