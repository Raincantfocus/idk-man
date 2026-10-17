extends SceneTree
## Exit 1 means art acceptance is incomplete, not that the game failed its tests.
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/characters/catalog.json")) as Dictionary
	var results: Array[Dictionary] = []
	var approved: int = 0
	for entry: Dictionary in catalog.variants:
		var definition: ZLCharacterVariant = load(String(entry.resource)) as ZLCharacterVariant
		var issues: PackedStringArray = definition.blockers()
		if issues.is_empty(): approved += 1
		results.append({"variant":String(definition.variant_id),"production_gate_passed":issues.is_empty(),"blockers":Array(issues)})
	var evidence: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/characters/phase1_evidence.json")) as Dictionary
	var pending: Array[String] = []
	for item: Dictionary in evidence.acceptance:
		if item.status != "verified": pending.append(String(item.id))
	var complete: bool = approved == catalog.variants.size() and approved >= 25 and pending.is_empty()
	var report: Dictionary = {"phase":1,"complete":complete,"approved_variants":approved,
		"total_variants":catalog.variants.size(),"variants":results,"pending_evidence":pending,
		"next_phase_authorized_by_user":true,"next_phase_ready":complete}
	var output: String = "user://phase1_acceptance_report.json"
	var file := FileAccess.open(output,FileAccess.WRITE)
	if file == null:
		push_error("Cannot write acceptance report")
		quit(2)
		return
	file.store_string(JSON.stringify(report,"  "))
	file.close()
	print("PHASE 1 ACCEPTANCE: ","COMPLETE" if complete else "INCOMPLETE","; ",approved,"/",catalog.variants.size()," production definitions; ",pending.size()," pending evidence items; ",output)
	quit(0 if complete else 1)
