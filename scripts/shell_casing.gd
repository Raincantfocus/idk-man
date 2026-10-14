extends RigidBody3D
## Cosmetic world-simulated casing; never collides with actors or deals damage.
var age := 0.0
func _ready() -> void:
	add_to_group("transient")
	add_to_group("shell_casing")
	process_mode = Node.PROCESS_MODE_PAUSABLE
	collision_layer = 0
	collision_mask = 1
	mass = 0.015
	continuous_cd = true
	linear_damp = 0.5
	angular_damp = 1.4
func _physics_process(dt: float) -> void:
	age += dt
	if age > 2.5:
		freeze = true
	if age > 5.0:
		queue_free()
