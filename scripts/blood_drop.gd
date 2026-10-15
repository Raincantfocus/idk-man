extends Node3D
## Cosmetic ballistic drop with swept world collision; independent of combat RNG.
var game
var velocity := Vector3.ZERO
var age := 0.0
var stain := false
var material: StandardMaterial3D
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group("transient")
	add_to_group("blood_drop")
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.014
	sphere.height = 0.028
	sphere.radial_segments = 6
	sphere.rings = 3
	mesh.mesh = sphere
	material = preload("res://scripts/surface_library.gd").make("tissue")
	mesh.material_override = material
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh)
func _physics_process(dt: float) -> void:
	age += dt
	if not game.gore_enabled or age > (20.0 if stain else 1.4):
		queue_free()
		return
	if stain: return
	velocity += Vector3.DOWN * 9.8 * dt
	var next := global_position + velocity * dt
	var query := PhysicsRayQueryParameters3D.create(global_position, next, 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		global_position = next
		return
	stain = true
	age = 0
	remove_from_group("blood_drop")
	var stains := get_tree().get_nodes_in_group("blood_stain")
	if stains.size() >= 64: stains[0].free()
	add_to_group("blood_stain")
	global_position = hit.position + hit.normal * 0.004
	global_basis = Basis(Quaternion(Vector3.UP, hit.normal))
	var mesh: MeshInstance3D = get_child(0)
	var plane := PlaneMesh.new()
	plane.size = Vector2(0.13, 0.24) * clampf(velocity.length() / 5.0, 0.6, 2.0)
	mesh.mesh = plane
	var shader := Shader.new()
	shader.code = "shader_type spatial; render_mode cull_disabled; void fragment(){vec2 p=UV*2.0-1.0; float a=atan(p.y,p.x); float edge=.78+.10*sin(a*7.0)+.07*cos(a*13.0); if(length(p)>edge) discard; ALBEDO=vec3(.12,.009,.006); ROUGHNESS=.22+.22*length(p); }"
	var wet := ShaderMaterial.new()
	wet.shader = shader
	mesh.material_override = wet
