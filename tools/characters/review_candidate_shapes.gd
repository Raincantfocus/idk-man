extends SceneTree
## Five shape variants of ONE unapproved kit; never the five-role acceptance sheet.
func _initialize() -> void: call_deferred("run")
func settle() -> void:
 for i: int in 8:await process_frame
 await RenderingServer.frame_post_draw
func run() -> void:
 root.size=Vector2i(1600,700);root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
 var world:=Node3D.new();root.add_child(world)
 var environment:=WorldEnvironment.new();environment.environment=Environment.new()
 environment.environment.background_mode=Environment.BG_COLOR
 environment.environment.background_color=Color(.12,.14,.17)
 environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 environment.environment.ambient_light_color=Color.WHITE;environment.environment.ambient_light_energy=.6
 world.add_child(environment)
 var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-30,-30,0);light.light_energy=1.6;world.add_child(light)
 var camera:=Camera3D.new();camera.position=Vector3(0,1,20);camera.fov=12;world.add_child(camera);camera.current=true
 var assemblies: Array[ZLCharacterAssembly]=[]
 var shapes: Array[String]=["lean","standard","broad","stocky","slender"]
 for i: int in shapes.size():
  var assembly:=ZLCharacterAssembly.new();world.add_child(assembly);assembly.position.x=(i-2)*1.6
  assert(assembly.configure(load("res://candidates/%s.tres"%shapes[i]) as ZLCharacterVariant,false),str(assembly.setup_errors))
  assemblies.append(assembly)
 var layer:=CanvasLayer.new();world.add_child(layer)
 var label:=Label.new();label.position=Vector2(24,24)
 label.text="UNAPPROVED KIT / FIVE AUTHORED SHAPE FITS / CAMERA 20 m FROM LINE\nLean — Standard — Broad — Stocky — Slender\n12-degree zoomed fit comparison; not gameplay visibility or role acceptance"
 layer.add_child(label)
 await settle()
 assert(root.get_texture().get_image().save_png("res://candidate_shapes_color.png")==OK)
 var draws: int=RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
 var post:=CanvasLayer.new();post.layer=10;root.add_child(post)
 var rect:=ColorRect.new();post.add_child(rect);rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var shader:=Shader.new();shader.code="shader_type canvas_item; uniform sampler2D screen_texture : hint_screen_texture, filter_nearest; void fragment(){ vec3 c=texture(screen_texture,SCREEN_UV).rgb; float v=dot(c,vec3(0.2126,0.7152,0.0722)); COLOR=vec4(vec3(v),1.0); }"
 var material:=ShaderMaterial.new();material.shader=shader;rect.material=material
 await settle()
 assert(root.get_texture().get_image().save_png("res://candidate_shapes_grayscale.png")==OK)
 rect.visible=false
 root.size=Vector2i(1920,1080)
 camera.fov=86
 for assembly: ZLCharacterAssembly in assemblies:assembly.update_distance(20.0)
 label.text="GAMEPLAY PROJECTION DIAGNOSTIC: 20 m / 86-degree FOV / LOD1 / 1920x1080\nFive shapes of one unapproved outfit; role differentiation and motion not accepted"
 await settle()
 assert(root.get_texture().get_image().save_png("res://candidate_gameplay_20m_color.png")==OK)
 rect.visible=true
 await settle()
 assert(root.get_texture().get_image().save_png("res://candidate_gameplay_20m_grayscale.png")==OK)
 print("SHAPE REVIEW: five same-kit body shapes; scene draws including UI ",draws,"; software frame times invalid")
 quit()
