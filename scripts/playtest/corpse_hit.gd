extends PhysicalBone3D
## Cosmetic-only forwarding; never touches damage, rewards or physical joint state.
var gore: Node
func take_damage(amount: float,point: Vector3,headshot: bool=false,_bypass: bool=false) -> void:
 if is_instance_valid(gore):
  var surface: Dictionary=get_meta("cosmetic_surface_hit",{})
  if not surface.get("point",Vector3.INF).is_equal_approx(point):surface={}
  gore.service.wound(gore.actor,point,surface.get("normal",Vector3.ZERO),surface.get("direction",Vector3.ZERO))
  gore.hit(amount,point,headshot,true)
