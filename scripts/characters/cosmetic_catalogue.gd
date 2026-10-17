extends Resource
class_name ZLCosmeticCatalogue
@export var looks: Array[ZLCosmeticLook] = []
@export var exclusion_radius_m: float = 8.0
@export var cosmetic_seed: int = 4102026

func blockers(production: bool = true) -> PackedStringArray:
	var errors := PackedStringArray()
	var ids: Dictionary[StringName,bool] = {}
	if looks.is_empty(): errors.append("No authored looks available")
	if not is_finite(exclusion_radius_m) or exclusion_radius_m<0: errors.append("Invalid radius")
	for look: ZLCosmeticLook in looks:
		if look == null:
			errors.append("Null look")
			continue
		if ids.has(look.look_id): errors.append("Duplicate look ID")
		ids[look.look_id] = true
		errors.append_array(look.blockers(production))
	return errors

func to_data() -> Dictionary:
	var entries: Array[Dictionary] = []
	for look: ZLCosmeticLook in looks:
		if look != null: entries.append(look.to_data())
	return {"schema":1,"cosmetic_seed":cosmetic_seed,"exclusion_radius_m":exclusion_radius_m,"looks":entries}
