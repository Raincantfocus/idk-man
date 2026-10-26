extends Node
## Render representative existing resources in a small offscreen viewport during the menu.
## This reduces first-use work but cannot guarantee driver shader-cache behavior.
var service: Node
var ready_for_play: bool=false
func _ready() -> void:call_deferred("warm")
func warm() -> void:
 var viewport:=SubViewport.new();viewport.size=Vector2i(128,128);viewport.own_world_3d=true
 viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;add_child(viewport)
 var stage:=Node3D.new();viewport.add_child(stage)
 var actor:=preload("res://scripts/ragdoll/anatomical_actor.gd").new();stage.add_child(actor)
 var settings: Dictionary=service.rig_settings.duplicate(true);settings.mass_role="enforcer"
 actor.setup(settings,service.ragdoll_budget)
 var camera:=Camera3D.new();stage.add_child(camera);camera.position=Vector3(0,1,3);camera.look_at(Vector3(0,1,0));camera.current=true
 var light:=DirectionalLight3D.new();stage.add_child(light);light.rotation_degrees=Vector3(-30,-30,0)
 var stain:=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=Vector2.ONE;stain.mesh=plane;stain.material_override=service.pools.shared_surface;stage.add_child(stain)
 var impact_stain:=MeshInstance3D.new();impact_stain.mesh=plane;impact_stain.material_override=preload("res://scripts/blood_drop.gd").stain_material();impact_stain.position=Vector3(.5,.01,0);stage.add_child(impact_stain)
 for i: int in 3:await get_tree().process_frame
 viewport.queue_free();ready_for_play=true
 service.log_once("warmup","INFO","Menu warmup complete: body, gear, animation libraries, ragdoll resources pool and impact-stain shaders. First-use stalls still require hardware profiling")
