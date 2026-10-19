extends RefCounted
## One shared tissue material for every cap instance; per-instance aging only.
var manifest: Dictionary
var folder: String
var tissue: ShaderMaterial
func configure(path: String) -> Error:
 var decoded: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
 if not decoded is Dictionary:return ERR_PARSE_ERROR
 manifest=decoded;folder=path.get_base_dir()
 if manifest.get("schema")!=2:return ERR_INVALID_DATA
 tissue=ShaderMaterial.new();tissue.shader=preload("tissue_atlas.gdshader")
 for pair: Array in [["albedo_atlas","tissue_albedo.png"],["normal_atlas","tissue_normal.png"],["orm_atlas","tissue_orm.png"],["flow_atlas","tissue_flow.png"]]:
  var texture: Texture2D=load(folder.path_join(pair[1])) as Texture2D
  if texture==null:return ERR_FILE_NOT_FOUND
  tissue.set_shader_parameter(pair[0],texture)
 return OK
func instantiate_cap(index: int, lod: int=0) -> Node3D:
 if index<0 or index>=manifest.variants.size():return null
 var name: String=manifest.variants[index].lods[clampi(lod,0,2)]
 if name!=name.get_file():return null
 var packed: PackedScene=load(folder.path_join(name)) as PackedScene
 if packed==null:return null
 var cap: Node3D=packed.instantiate() as Node3D
 for node: Node in cap.find_children("*","MeshInstance3D",true,false):
  var mesh: MeshInstance3D=node as MeshInstance3D
  mesh.material_override=tissue
  mesh.set_instance_shader_parameter("wetness",.85)
  mesh.set_instance_shader_parameter("blood_fill",.45)
 for entry: Dictionary in manifest.sockets:
  var marker:=Marker3D.new();marker.name=entry.name
  marker.position=Vector3(entry.position[0],entry.position[1],entry.position[2]);cap.add_child(marker)
 return cap
func instantiate_head(index: int, config: Dictionary, direction: Vector3, spin: Vector3) -> RigidBody3D:
 var body:=RigidBody3D.new();body.mass=float(config.head_mass_kg);body.collision_layer=8;body.collision_mask=1;body.continuous_cd=true
 body.linear_damp=.3;body.angular_damp=1.2
 var shell: Node3D=(load(folder.path_join(manifest.head_exterior)) as PackedScene).instantiate() as Node3D
 body.add_child(shell)
 var cap: Node3D=instantiate_cap(index)
 # Flip local outward Y toward the underside; paired source boundary verification
 # must be rerun for this rotation before claiming welded skin continuity.
 for node: Node in cap.find_children("*","MeshInstance3D",true,false):
  (node as MeshInstance3D).set_instance_shader_parameter("underside",1.0)
 body.add_child(cap)
 var collider:=CollisionShape3D.new();var shape:=CapsuleShape3D.new();shape.radius=float(config.head_collider.radius_m);shape.height=float(config.head_collider.height_m);collider.shape=shape;collider.position.y=float(config.head_collider.center_y_m);body.add_child(collider)
 body.angular_velocity=spin.limit_length(1.0)*float(config.max_angular_speed)
 body.set_meta("launch_impulse",direction.limit_length(1.0)*float(config.max_launch_impulse_ns))
 return body
func instantiate_fragment(index: int, config: Dictionary) -> RigidBody3D:
 if index<0 or index>=manifest.head_pop.size():return null
 var entry: Dictionary=manifest.head_pop[index]
 var body:=RigidBody3D.new();body.mass=float(config.head_mass_kg)/4;body.collision_layer=8;body.collision_mask=1;body.continuous_cd=true;body.linear_damp=.5;body.angular_damp=1.5
 var shell: Node3D=(load(folder.path_join(entry.path)) as PackedScene).instantiate() as Node3D;body.add_child(shell)
 var points:=PackedVector3Array()
 for node: Node in shell.find_children("*","MeshInstance3D",true,false):
  var mesh: MeshInstance3D=node as MeshInstance3D
  for surface: int in mesh.mesh.get_surface_count():
   var source_material: Material=mesh.mesh.surface_get_material(surface)
   if source_material!=null and source_material.resource_name.begins_with("Shared_Neck_Tissue"):
    mesh.set_surface_override_material(surface,tissue);mesh.set_instance_shader_parameter("fragment_cap",true)
   var arrays: Array=mesh.mesh.surface_get_arrays(surface)
   for p: Vector3 in arrays[Mesh.ARRAY_VERTEX]:points.append(mesh.transform*p)
 # One convex proxy per source-derived piece; generated once then recycled.
 var shape:=ConvexPolygonShape3D.new();shape.points=points
 var collider:=CollisionShape3D.new();collider.shape=shape;body.add_child(collider)
 return body
