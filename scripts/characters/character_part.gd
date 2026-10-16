extends Resource
class_name ZLCharacterPart
## Presentation-only asset. Colliders, gameplay scripts and loot are forbidden.
@export var part_id: StringName
@export var source_url: String
@export var license_id: String
@export var body_shape: StringName
@export var lod_scenes: Array[PackedScene] = []
@export var socket_bone: StringName
@export var socket_transform: Transform3D = Transform3D.IDENTITY
@export var materials: Array[Material] = []
@export var material_slots: int = 1
@export var reviewed: bool = false

func to_data() -> Dictionary:
 var paths: Array[String] = []
 var material_paths: Array[String] = []
 for material: Material in materials: material_paths.append(material.resource_path)
 for scene: PackedScene in lod_scenes: paths.append(scene.resource_path)
 return {"part_id":String(part_id),"source_url":source_url,"license_id":license_id,
  "body_shape":String(body_shape),"lod_scenes":paths,"socket_bone":String(socket_bone),
  "socket_transform":var_to_str(socket_transform),"materials":material_paths,"material_slots":material_slots,"reviewed":reviewed}
