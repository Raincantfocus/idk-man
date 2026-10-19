extends "res://tools/animation/animation_review.gd"
## Isolated fitting review; no live enemy or gameplay integration.
var fitting_meshes: Dictionary
var fitting_driver: RefCounted
var reveal_body: bool=false
var mask_debug: bool=false
var correctives_enabled: bool=true
func _ready() -> void:
 super._ready()
 var patch: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/clipping/review_patch.json"))
 fitting_meshes=preload("res://scripts/clipping/apply_patch.gd").apply(model_root,patch)
 fitting_driver=preload("res://scripts/clipping/corrective_driver.gd").new();fitting_driver.configure(skeleton,fitting_meshes,patch)
func _process(delta: float) -> void:
 super._process(delta)
 fitting_driver.advance(camera.global_position.distance_to(skeleton.global_position) if correctives_enabled else INF)
 status.text+="\nFITTING CANDIDATE: NOT APPROVED | R reveal skin | M mask | C correctives\nUnapproved: remaining penetrations, lining/cuffs, torn gear, flinch/death, role/body matrix"
func _unhandled_key_input(event: InputEvent) -> void:
 if not event is InputEventKey or not event.pressed or event.echo:return
 match event.keycode:
  KEY_R:reveal_body=not reveal_body
  KEY_M:mask_debug=not mask_debug
  KEY_C:correctives_enabled=not correctives_enabled
 fitting_meshes.Body_LOD0.set_instance_shader_parameter("reveal",float(reveal_body))
 fitting_meshes.Body_LOD0.set_instance_shader_parameter("mask_view",mask_debug)
