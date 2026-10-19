extends Resource
## Portable cosmetic tuning. No gameplay hitbox, damage or reward ownership.
@export var id: StringName
@export var bone: StringName
@export var hit_zone_collider: NodePath
@export var trauma_hp: float=100.0
@export var thresholds:=PackedFloat32Array([10,30,60,100])
@export var sever_threshold: float=100.0
@export var allowed_weapon_classes:=PackedStringArray(["melee","rifle","shotgun","explosive"])
@export var weapon_multipliers: Dictionary={"melee":1.0,"rifle":1.0,"shotgun":1.5,"explosive":1.8}
@export var min_impact_energy: float=1.0
@export var cap_variants: Dictionary={}
@export var parent_zone: StringName
@export var child_zones:=PackedStringArray()
@export var max_tilt_degrees: float=30.0
@export var close_shotgun_m: float=6.0
@export var distance_falloff_per_m: float=0.015
@export var can_sever: bool=true
@export var gameplay_consequences: bool=false
func to_dictionary() -> Dictionary:
 return {"id":String(id),"bone":String(bone),"hit_zone_collider":String(hit_zone_collider),"trauma_hp":trauma_hp,"thresholds":Array(thresholds),"sever_threshold":sever_threshold,"allowed_weapon_classes":Array(allowed_weapon_classes),"weapon_multipliers":weapon_multipliers.duplicate(true),"min_impact_energy":min_impact_energy,"cap_variants":cap_variants.duplicate(true),"parent_zone":String(parent_zone),"child_zones":Array(child_zones),"max_tilt_degrees":max_tilt_degrees,"close_shotgun_m":close_shotgun_m,"distance_falloff_per_m":distance_falloff_per_m,"can_sever":can_sever,"gameplay_consequences":gameplay_consequences}
