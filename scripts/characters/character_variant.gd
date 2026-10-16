extends Resource
class_name ZLCharacterVariant
## Immutable presentation selection; no health, movement, weapon or reward data.
@export var variant_id: StringName
@export var role: StringName
@export var body_shape: StringName
@export var shape_parameters: Vector3 = Vector3.ZERO
@export var body_lods: Array[PackedScene] = []
@export var parts: Array[ZLCharacterPart] = []
@export var required_parts: Array[StringName] = []
@export var camo_primary: Color = Color.WHITE
@export var camo_secondary: Color = Color.WHITE
@export var camo_tertiary: Color = Color.WHITE
@export var bone_map: BoneMap
@export var lod_ranges: PackedFloat32Array = PackedFloat32Array([0,12,25,45])
@export var lod_margin: float = 1.0
@export var body_material_reviewed: bool = false
@export var correctives_reviewed: bool = false
@export var wound_seams_reviewed: bool = false
@export var soldier_lods_reviewed: bool = false

func blockers() -> PackedStringArray:
 var issues := PackedStringArray()
 if body_lods.size()!=4: issues.append("Four body LODs required")
 if bone_map==null: issues.append("Humanoid BoneMap missing")
 var present: Array[StringName] = []
 for part: ZLCharacterPart in parts:
  present.append(part.part_id)
  if part.body_shape!=body_shape: issues.append("Part shape mismatch: "+String(part.part_id))
  if part.license_id.is_empty() or part.source_url.is_empty(): issues.append("Part provenance missing: "+String(part.part_id))
  if part.lod_scenes.size()!=4: issues.append("Part LODs missing: "+String(part.part_id))
  if not part.reviewed: issues.append("Part fit not reviewed: "+String(part.part_id))
 for required: StringName in required_parts:
  if not present.has(required): issues.append("Missing part: "+String(required))
 if not body_material_reviewed: issues.append("UV-specific body PBR atlas missing")
 if not correctives_reviewed: issues.append("Joint corrective shapes not reviewed")
 if not wound_seams_reviewed: issues.append("Wound boundary seams not reviewed")
 if not soldier_lods_reviewed: issues.append("Assembled soldier LOD budgets not reviewed")
 return issues

func to_data() -> Dictionary:
 var paths: Array[String] = []
 var part_data: Array[Dictionary] = []
 for scene: PackedScene in body_lods: paths.append(scene.resource_path)
 for part: ZLCharacterPart in parts: part_data.append(part.to_data())
 return {"schema":1,"variant_id":String(variant_id),"role":String(role),"body_shape":String(body_shape),
  "shape_parameters":[shape_parameters.x,shape_parameters.y,shape_parameters.z],"body_lods":paths,
  "parts":part_data,"required_parts":Array(required_parts),"bone_map":bone_map.resource_path if bone_map else "",
  "camo_primary":[camo_primary.r,camo_primary.g,camo_primary.b],
  "camo_secondary":[camo_secondary.r,camo_secondary.g,camo_secondary.b],
  "camo_tertiary":[camo_tertiary.r,camo_tertiary.g,camo_tertiary.b],
  "lod_ranges":Array(lod_ranges),"lod_margin":lod_margin,"release_blockers":Array(blockers())}
