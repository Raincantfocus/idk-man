extends Resource
class_name ZLCosmeticLook
## Concrete authored selection, not a generator for missing parts.
@export var look_id: StringName
@export var role: StringName
@export var base_body_id: StringName
@export var camo_id: StringName
@export_range(0,5) var camo_layer: int = 0
@export var headgear_id: StringName
@export var head_id: StringName
@export var hair_id: StringName
@export var facial_hair_id: StringName
@export var glove_id: StringName
@export var boot_id: StringName
@export var sleeve_id: StringName
@export var kit_id: StringName
@export var part_ids: PackedStringArray
@export var build: Vector4 = Vector4.ZERO
@export var skin_tone: Color = Color.WHITE
@export var accent: Color = Color.WHITE
@export_range(0,1) var dirt: float = 0
@export_range(0,1) var wear: float = 0
@export var definition: ZLCharacterVariant

func combination_key() -> String:
	return JSON.stringify([String(base_body_id),String(camo_id),String(headgear_id)])

func snapshot() -> ZLCosmeticLook:
	var copy := duplicate() as ZLCosmeticLook
	copy.part_ids = part_ids.duplicate()
	return copy

func blockers(production: bool = true) -> PackedStringArray:
	var errors := PackedStringArray()
	if not role in [&"rusher",&"enforcer",&"shield",&"flusher",&"elite"]: errors.append("Unknown role")
	for id: StringName in [look_id,base_body_id,camo_id,headgear_id,head_id,glove_id,boot_id,sleeve_id,kit_id]:
		if id.is_empty(): errors.append("Required appearance ID empty")
	if role == &"rusher" and not String(headgear_id).begins_with("bare_"): errors.append("Rusher must be bareheaded")
	if not build.is_finite() or absf(build.x)>1 or absf(build.y)>1 or absf(build.z)>1 or absf(build.w)>0.05: errors.append("Build outside authored limits")
	if camo_layer<0 or camo_layer>5: errors.append("Camouflage layer outside six-layer atlas")
	if not is_finite(dirt) or not is_finite(wear) or dirt<0 or dirt>1 or wear<0 or wear>1: errors.append("Invalid dirt/wear")
	if production:
		if definition == null: errors.append("Fitted definition missing")
		else:
			if definition.role != role: errors.append("Definition role mismatch")
			errors.append_array(definition.blockers())
	return errors

func to_data() -> Dictionary:
	return {"schema":1,"look_id":String(look_id),"role":String(role),"base_body_id":String(base_body_id),
		"camo_id":String(camo_id),"camo_layer":camo_layer,"headgear_id":String(headgear_id),"head_id":String(head_id),
		"hair_id":String(hair_id),"facial_hair_id":String(facial_hair_id),"glove_id":String(glove_id),
		"boot_id":String(boot_id),"sleeve_id":String(sleeve_id),"kit_id":String(kit_id),"part_ids":Array(part_ids),
		"build":[build.x,build.y,build.z,build.w],"skin_tone":[skin_tone.r,skin_tone.g,skin_tone.b,skin_tone.a],
		"accent":[accent.r,accent.g,accent.b,accent.a],"dirt":dirt,"wear":wear,
		"definition":definition.resource_path if definition else ""}
