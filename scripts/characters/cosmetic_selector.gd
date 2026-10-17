extends RefCounted
class_name ZLCosmeticSelector
## Presentation allocator; no gameplay RNG, damage, death or reward calls.
var last_error: String = ""
var _rng := RandomNumberGenerator.new()
var _looks: Array[ZLCosmeticLook] = []
var _radius_squared: float = 0
var _last_key: String = ""
var _owners: Dictionary[int,Dictionary] = {}
var _configured: bool = false

func configure(catalogue: ZLCosmeticCatalogue, review_only: bool = false) -> bool:
	_configured = false
	last_error = ""
	if catalogue == null:
		last_error = "Missing catalogue"
		return false
	var errors: PackedStringArray = catalogue.blockers(not review_only)
	if not errors.is_empty():
		last_error = "; ".join(errors)
		return false
	_looks.clear()
	for look: ZLCosmeticLook in catalogue.looks: _looks.append(look.snapshot())
	_rng.seed = catalogue.cosmetic_seed
	_radius_squared = catalogue.exclusion_radius_m * catalogue.exclusion_radius_m
	_owners.clear()
	_last_key = ""
	_configured = true
	return true

func reserve(owner: Node3D, role: StringName) -> ZLCosmeticLook:
	last_error = ""
	if not _configured or not is_instance_valid(owner) or not owner.is_inside_tree():
		last_error = "Valid catalogue and live scene owner required"
		return null
	_prune()
	var id: int = owner.get_instance_id()
	if _owners.has(id):
		last_error = "Owner already reserved"
		return null
	var excluded: Dictionary[String,bool] = {_last_key:true}
	for record: Dictionary in _owners.values():
		var other: Node3D = (record.owner as WeakRef).get_ref() as Node3D
		if other.global_position.distance_squared_to(owner.global_position)<=_radius_squared:
			excluded[(record.look as ZLCosmeticLook).combination_key()] = true
	var eligible: Array[ZLCosmeticLook] = []
	for look: ZLCosmeticLook in _looks:
		if look.role == role and not excluded.has(look.combination_key()): eligible.append(look)
	if eligible.is_empty():
		last_error = "No compatible unused appearance for " + String(role)
		return null
	var selected: ZLCosmeticLook = eligible[_rng.randi_range(0,eligible.size()-1)].snapshot()
	_owners[id] = {"owner":weakref(owner),"look":selected}
	_last_key = selected.combination_key()
	return selected.snapshot()

func look_for(owner: Node3D) -> ZLCosmeticLook:
	if not is_instance_valid(owner): return null
	var record: Dictionary = _owners.get(owner.get_instance_id(),{})
	return (record.look as ZLCosmeticLook).snapshot() if not record.is_empty() else null

func transfer_to_corpse(owner: Node3D, anchor: Node3D) -> ZLCosmeticLook:
	last_error = ""
	if not is_instance_valid(owner) or not is_instance_valid(anchor) or not anchor.is_inside_tree():
		last_error = "Valid corpse anchor required"
		return null
	var id: int = owner.get_instance_id()
	var corpse_id: int = anchor.get_instance_id()
	if not _owners.has(id) or _owners.has(corpse_id):
		last_error = "Owner missing or corpse already reserved"
		return null
	var record: Dictionary = _owners[id]
	_owners.erase(id)
	_owners[corpse_id] = {"owner":weakref(anchor),"look":record.look}
	return (record.look as ZLCosmeticLook).snapshot()

func release(owner: Node3D) -> void:
	if is_instance_valid(owner): _owners.erase(owner.get_instance_id())

func active_count() -> int:
	_prune()
	return _owners.size()

func _prune() -> void:
	for id: int in _owners.keys():
		var owner: Node3D = (_owners[id].owner as WeakRef).get_ref() as Node3D
		if owner == null or not owner.is_inside_tree(): _owners.erase(id)
