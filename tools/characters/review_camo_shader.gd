extends SceneTree
## Flat shader fixtures only. These swatches are not authored character art.
func _initialize() -> void: call_deferred("run")
func solid(color: Color) -> Image:
 var image:=Image.create(8,8,false,Image.FORMAT_RGBA8)
 image.fill(color)
 return image
func run() -> void:
 assert(ClassDB.class_has_method("ImageTextureLayered","create_from_images"))
 assert(ClassDB.class_has_method("Camera3D","unproject_position"))
 root.size=Vector2i(1000,300)
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
 var world:=Node3D.new();root.add_child(world)
 var camera:=Camera3D.new();world.add_child(camera)
 camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=5.0;camera.position=Vector3(0,0,3);camera.current=true
 var material:=ShaderMaterial.new();material.shader=load("res://scripts/characters/camo_pbr.gdshader")
 material.set_shader_parameter("albedo_map",ImageTexture.create_from_image(solid(Color.WHITE)))
 material.set_shader_parameter("normal_map",ImageTexture.create_from_image(solid(Color(.5,.5,1))))
 material.set_shader_parameter("orm_map",ImageTexture.create_from_image(solid(Color(1,.8,0))))
 material.set_shader_parameter("surface_mask",ImageTexture.create_from_image(solid(Color(0,1,0))))
 material.set_shader_parameter("detail_mask",ImageTexture.create_from_image(solid(Color(0,0,0,0))))
 material.set_shader_parameter("variation_masks_enabled",true)
 var patterns:=Texture2DArray.new()
 var images: Array[Image]=[solid(Color.RED),solid(Color.GREEN),solid(Color.BLUE),solid(Color.RED),solid(Color.GREEN),solid(Color.BLUE)]
 assert(patterns.create_from_images(images)==OK)
 material.set_shader_parameter("camo_patterns",patterns)
 var env:=WorldEnvironment.new();env.environment=Environment.new()
 env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 env.environment.ambient_light_color=Color.WHITE;env.environment.ambient_light_energy=1;world.add_child(env)
 var quad:=QuadMesh.new();quad.size=Vector2(.8,.8)
 for i: int in 5:
  var mesh:=MeshInstance3D.new();mesh.mesh=quad;mesh.material_override=material
  mesh.position=Vector3((i-2)*.95,0,0);world.add_child(mesh)
  mesh.set_instance_shader_parameter("primary_color",Color.RED)
  mesh.set_instance_shader_parameter("secondary_color",Color.GREEN)
  mesh.set_instance_shader_parameter("tertiary_color",Color.BLUE)
  mesh.set_instance_shader_parameter("camo_layer",i%3)
 for i: int in 12:await process_frame
 await RenderingServer.frame_post_draw
 var capture: Image=root.get_texture().get_image()
 assert(capture.save_png("user://camo_array_review.png")==OK)
 # Sample projected mesh centres rather than assuming a viewport aspect mode.
 var pa: Vector2=camera.unproject_position(Vector3(-1.9,0,0))
 var pb: Vector2=camera.unproject_position(Vector3(-.95,0,0))
 var pc: Vector2=camera.unproject_position(Vector3.ZERO)
 var a: Color=capture.get_pixel(int(pa.x),int(pa.y))
 var b: Color=capture.get_pixel(int(pb.x),int(pb.y))
 var c: Color=capture.get_pixel(int(pc.x),int(pc.y))
 assert(a.r>a.g*2 and b.g>b.r*2 and c.b>c.r*2,"Shared material must show independent RGB pattern layers")
 print("CAMO ARRAY REVIEW PASS; three independently selected layers; screenshot user://camo_array_review.png")
 quit()
