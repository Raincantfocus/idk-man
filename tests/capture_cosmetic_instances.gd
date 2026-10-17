extends SceneTree
func _initialize() -> void: call_deferred("run")
func texture(color: Color) -> ImageTexture:
	var image := Image.create(2,2,false,Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)
func run() -> void:
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size=Vector2i.ZERO
	root.size=Vector2i(640,360)
	var world := Node3D.new()
	root.add_child(world)
	var camera := Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=4
	camera.position=Vector3(0,0,4)
	world.add_child(camera)
	camera.current=true
	world.add_child(DirectionalLight3D.new())
	var material := ShaderMaterial.new()
	material.shader=preload("res://scripts/characters/camo_pbr.gdshader")
	material.set_shader_parameter("albedo_map",texture(Color.WHITE))
	material.set_shader_parameter("normal_map",texture(Color(0.5,0.5,1)))
	material.set_shader_parameter("orm_map",texture(Color(1,0.8,0)))
	material.set_shader_parameter("camo_mask",texture(Color.RED))
	var meshes: Array[MeshInstance3D]=[]
	for i: int in 2:
		var mesh := MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size=Vector2(1.4,1.4)
		mesh.mesh=quad
		mesh.material_override=material
		mesh.position.x=-0.9 if i==0 else 0.9
		mesh.set_instance_shader_parameter("primary_color",Color(0.85,0.03,0.03) if i==0 else Color(0.03,0.03,0.85))
		world.add_child(mesh)
		meshes.append(mesh)
	for i: int in 8: await process_frame
	await RenderingServer.frame_post_draw
	var image: Image=root.get_texture().get_image()
	var path: String=OS.get_environment("ZL_COSMETIC_CAPTURE")
	if path.is_empty(): path="user://cosmetic-instance-swatches.png"
	var error: Error=image.save_png(path)
	var lp: Vector2=camera.unproject_position(meshes[0].global_position)
	var rp: Vector2=camera.unproject_position(meshes[1].global_position)
	var left: Color=image.get_pixel(int(lp.x),int(lp.y))
	var right: Color=image.get_pixel(int(rp.x),int(rp.y))
	var ok: bool=error==OK and left.r>left.b*2 and right.b>right.r*2 and meshes[0].material_override==meshes[1].material_override
	print("INSTANCE RENDER RESULT: ","PASS" if ok else "FAIL"," left=",left," right=",right," shared_materials=1")
	quit(0 if ok else 1)
