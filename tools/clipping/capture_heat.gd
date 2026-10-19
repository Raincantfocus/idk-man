extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 root.size=Vector2i(1000,900)
 var args: PackedStringArray=OS.get_cmdline_user_args();var heat: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(args[0]));var output: String=args[1]
 var viewer: Node=(load("res://baseline_review.tscn" if FileAccess.file_exists("res://baseline_review.tscn") else "res://review.tscn") as PackedScene).instantiate();root.add_child(viewer);viewer.set_process(false)
 var patched_meshes: Dictionary={}
 var patch: Dictionary={}
 if args.size()>2:
  patch=JSON.parse_string(FileAccess.get_file_as_string(args[2]))
  patched_meshes=preload("res://scripts/clipping/apply_patch.gd").apply(viewer.model_root,patch)
 viewer.controller.preview_clip(StringName(heat.worst.clip));viewer.controller.player.seek(float(heat.worst.time),true);viewer.skeleton.force_update_all_bone_transforms()
 if patch.has("corrective_rules"):
  var driver=preload("res://scripts/clipping/corrective_driver.gd").new();driver.configure(viewer.skeleton,patched_meshes,patch);driver.advance(4.0)
 viewer.status.text="AUDIT | %s | frame %d | original camera\nAvailable fixture only; acceptance pending" % [heat.worst.clip,int(heat.worst.frame)]
 for i: int in 4:await process_frame
 await RenderingServer.frame_post_draw
 assert(root.get_texture().get_image().save_png(output+"_original.png")==OK)
 var body: MeshInstance3D=viewer.model_root.find_children("Body_LOD0","MeshInstance3D",true,false)[0] as MeshInstance3D
 var arrays: Array=body.mesh.surface_get_arrays(0);var colors:=PackedColorArray()
 for depth: float in heat.max_heat_m:
  colors.append(Color.GREEN.lerp(Color.RED,clampf(depth/.01,0,1)))
 arrays[Mesh.ARRAY_COLOR]=colors
 # Bake current corrective weights into bind-space positions for the heat mesh.
 var base: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
 var deformed: PackedVector3Array=base.duplicate()
 var shapes: Array[Array]=body.mesh.surface_get_blend_shape_arrays(0)
 for j: int in shapes.size():
  var weight: float=body.get_blend_shape_value(j)
  var target: PackedVector3Array=shapes[j][Mesh.ARRAY_VERTEX]
  for i: int in base.size():deformed[i]+=(target[i]-base[i])*weight
 arrays[Mesh.ARRAY_VERTEX]=deformed
 var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays);body.mesh=mesh
 var material:=ShaderMaterial.new();var shader:=Shader.new();shader.code="shader_type spatial; render_mode unshaded; void fragment(){ALBEDO=COLOR.rgb;}";material.shader=shader;body.material_override=material
 for garment: MeshInstance3D in viewer.gear:garment.visible=false
 viewer.status.text="AUDIT HEAT | maximum across all 1,370 sampled poses\nGreen 0 mm | red >=10 mm | gear hidden for inspection\nPose: %s frame %d | same camera" % [heat.worst.clip,int(heat.worst.frame)]
 for i: int in 4:await process_frame
 await RenderingServer.frame_post_draw
 assert(root.get_texture().get_image().save_png(output+"_heat.png")==OK)
 print("AUDIT_HEAT_CAPTURED");quit()
