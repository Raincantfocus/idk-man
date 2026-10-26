extends RigidBody3D
## Hitscan target only; corpse damage never issues kill rewards or loot.
var corpse: Node3D
var region := "torso"
func take_damage(amount: float, _point: Vector3, _headshot: bool = false, _bypass: bool = false) -> void:
	if is_instance_valid(corpse):
		if corpse.game.presentation != null and not corpse.game.presentation.can_legacy_sever(corpse): return
		corpse.damage_region(region, amount)
