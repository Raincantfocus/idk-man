extends StaticBody3D
## Settled-corpse cosmetic hit forwarding; no reward or solver changes.
var gore: Node
func take_damage(amount: float,point: Vector3,headshot: bool=false,_bypass: bool=false) -> void:
 if is_instance_valid(gore):gore.hit(amount,point,headshot,true)
