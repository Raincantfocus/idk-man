extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var game: Node=load("res://scenes/main.tscn").instantiate();game.is_test=true;root.add_child(game);game.set_process(false)
 var enemy: Node=game.spawn_enemy("enforcer",Vector3.ZERO)
 var materials: Array=[];var triangles: int=0;var surfaces: int=0
 for mesh: MeshInstance3D in enemy.animated_visual.actor.presentation.find_children("*","MeshInstance3D",true,false):
  for surface: int in mesh.mesh.get_surface_count():
   surfaces+=1;var arrays: Array=mesh.mesh.surface_get_arrays(surface)
   triangles+=(arrays[Mesh.ARRAY_INDEX].size() if arrays[Mesh.ARRAY_INDEX]!=null else arrays[Mesh.ARRAY_VERTEX].size())/3
   var material: Material=mesh.get_active_material(surface)
   if not material in materials:materials.append(material)
 var report: Dictionary={"shared_by_roles":["rusher","enforcer","shield","flusher","elite"],"triangles":triangles,"surfaces":surfaces,"materials":materials.size(),"bones":enemy.animated_visual.actor.skeleton.get_bone_count(),"lod":"single imported review LOD; no distance LOD switching","draw_call_note":"surfaces are submissions per pass, not whole-frame draw calls; shadows/lights add passes"}
 var file:=FileAccess.open("res://test-output/playtest-assets.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close();print("ASSET_AUDIT ",JSON.stringify(report))
 game.free();await process_frame;quit()
