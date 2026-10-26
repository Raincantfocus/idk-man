extends PhysicalBone3D
## Cosmetic-only forwarding; never touches damage, rewards or physical joint state.
var gore: Node
func take_damage(amount: float,point: Vector3,headshot: bool=false,_bypass: bool=false) -> void:
 if is_instance_valid(gore):gore.hit(amount,point,headshot,true)
