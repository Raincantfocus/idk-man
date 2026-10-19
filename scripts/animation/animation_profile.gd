extends Resource
## Cosmetic tuning with a lossless JSON export; no gameplay authority.
@export var run_reference_speed_mps: float=5.0
@export var speed_blend_seconds: float=.15
@export var fire_fade_in_seconds: float=.06
@export var fire_fade_out_seconds: float=.12
@export var reload_fade_in_seconds: float=.12
@export var reload_fade_out_seconds: float=.18
@export var world_clock_only: bool=true
@export var root_motion_drives_gameplay: bool=false
@export var live_enemy_enabled: bool=false
@export var missing_clips: PackedStringArray
@export var upper_body_roots:=PackedStringArray(["Spine"])
@export var clips: Dictionary={"hold":"hold","run":"run_loop","fire":"fire","reload":"reload_cover"}
func to_dictionary() -> Dictionary:
 var result: Dictionary={}
 for key: String in ["run_reference_speed_mps","speed_blend_seconds","fire_fade_in_seconds","fire_fade_out_seconds","reload_fade_in_seconds","reload_fade_out_seconds","world_clock_only","root_motion_drives_gameplay","live_enemy_enabled","missing_clips","upper_body_roots","clips"]:
  var value: Variant=get(key);result[key]=Array(value) if value is PackedStringArray else value
 return result
