extends StaticBody3D
var arena
var kind := "fuel"
var original_position := Vector3.ZERO
var health := 20.0
var stagger := 0.0
var countdown := -1.0
var spent := false
var falling := false
var fall_speed := 0.0
var warning: Node3D
func reset_hazard() -> void:
 health = 20
 countdown = -1
 spent = false
 falling = false
 fall_speed = 0
 position = original_position
 collision_layer = 1
 visible = true
 if is_instance_valid(warning): warning.free()
func take_damage(amount: float, _hit: Vector3, _headshot: bool = false, _bypass: bool = false) -> void:
 if spent or countdown >= 0 or falling: return
 health -= amount
 if health > 0: return
 if kind == "fuel": detonate()
 else:
  countdown = 3.0
  warning = arena.box(Vector3(position.x,.04,position.z),Vector3(10,.03,5),arena.palette("amber"),false)
  arena.game.notice("CRANE LOAD // CLEAR MARKED AREA // 3s",3)
  arena.game.sound.play_cue("wave")
func _physics_process(dt: float) -> void:
 if arena == null or arena.game == null or not arena.game.is_playing(): return
 if countdown >= 0:
  countdown -= dt
  if countdown <= 0:
   countdown = -1
   falling = true
 if falling:
  fall_speed += 24*dt
  position.y = maxf(1,position.y-fall_speed*dt)
  if position.y <= 1:
   falling = false
   detonate()
func detonate() -> void:
 if spent: return
 spent = true
 countdown = -1
 if is_instance_valid(warning): warning.free()
 if kind == "fuel":
  collision_layer = 0
  visible = false
 var game = arena.game
 for enemy in game.enemies.duplicate():
  if not is_instance_valid(enemy) or not enemy.alive: continue
  if _inside(enemy.global_position): enemy.take_damage(1200 if kind=="crane" else 220,enemy.global_position+Vector3.UP,false,true)
 if _inside(game.player.global_position): game.player.take_damage(150 if kind=="crane" else 65,position,.4)
 game.impact(position,Color("f9a653"),16)
 game.sound.play_cue("explosion")
 if kind == "crane":
  arena.blockers.append(AABB(position-Vector3(5,1,2.5),Vector3(10,2,5)))
  arena._build_navigation()
func _inside(point: Vector3) -> bool:
 if kind == "crane": return absf(point.x-position.x)<=5 and absf(point.z-position.z)<=2.5 and point.y<3
 if point.distance_to(position)>4.5: return false
 var ray := PhysicsRayQueryParameters3D.create(position+Vector3.UP,point+Vector3.UP,1)
 ray.exclude = [get_rid()]
 return get_world_3d().direct_space_state.intersect_ray(ray).is_empty()
