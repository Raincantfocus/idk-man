extends CanvasLayer
## This file is excluded from Windows release exports and loaded only in debug builds.
var service: Node
var label: Label
var clip_index: int=-1
var step: int=0
func _ready() -> void:
 process_mode=Node.PROCESS_MODE_ALWAYS
 label=Label.new();add_child(label);label.position=Vector2(12,145);label.add_theme_font_size_override("font_size",14)
func _process(_delta: float) -> void:
 step+=1
 if step%15!=0:return
 var active: int=0
 for actor: Node in service.corpse_nodes:
  if is_instance_valid(actor) and actor.is_simulating():active+=1
 var corpse_count: int=service.corpse_nodes.size()
 for corpse: Node in service.game.corpses:
  if is_instance_valid(corpse):
   corpse_count+=1
   if corpse.active:active+=1
 var fps: float=Engine.get_frames_per_second()
 label.text="TEST BUILD | %s | gore %s\nFPS %.0f / %.2f ms | enemies %d | ragdolls %d | corpses %d\ngibs %d | decals/stains %d | calls %d | primitives %d\nF1–F5 spawn roles | F6 kill | Shift+F6 dismember | F7 death clip\nF8 gore | F9 old/new | F10 clear | F11 slow-mo\nForced clip: %s" % ["NEW (shared fallback)" if service.new_enemies else "OLD",["Off","Reduced","Full"][service.game.gore_level],fps,1000/maxf(fps,1),service.game.enemies.size(),active,corpse_count,legacy_gibs(),service.blood_budget.total(&"decals"),int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),service.forced_clip]
 if active>6:service.log_once("ragdoll_overrun","BUDGET","More than six simulating corpses; budget's LITE simulation also counts. Extra corpses evicted by integration service.")
func _unhandled_input(event: InputEvent) -> void:
 if not event is InputEventKey or not event.pressed or event.echo:return
 var game: Node=service.game
 var key: int=event.physical_keycode
 if key>=KEY_F1 and key<=KEY_F5 and game.is_playing():
  var camera: Camera3D=game.player.camera
  var start: Vector3=camera.global_position
  var hit: Dictionary=game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(start,start-camera.global_basis.z*30,1))
  var point: Vector3=hit.position if not hit.is_empty() else start-camera.global_basis.z*6
  game.spawn_enemy(["rusher","enforcer","shield","flusher","elite"][key-KEY_F1],point+Vector3.UP*.1)
 elif key==KEY_F6 and game.is_playing():
  var nearest: Node3D=null
  for enemy: Node3D in game.enemies:
   if is_instance_valid(enemy) and (nearest==null or enemy.global_position.distance_squared_to(game.player.global_position)<nearest.global_position.distance_squared_to(game.player.global_position)):nearest=enemy
  if nearest!=null:nearest.take_damage(100000,nearest.global_position+Vector3.UP*1.7,true,true)
  if event.shift_pressed:service.log_once("debug_sever","FALLBACK","New mesh sever unavailable: wound-only. F9 old enemies enables existing limb severing.")
 elif key==KEY_F7:
  var ids: Array[String]=[""]
  for entry: Dictionary in service.clip_catalogue:ids.append(String(entry.id))
  clip_index=(clip_index+1)%ids.size();service.forced_clip=ids[clip_index]
 elif key==KEY_F8:game.set_gore_level((game.gore_level+1)%3)
 elif key==KEY_F9:service.toggle_models()
 elif key==KEY_F10:service.clear_corpses()
 elif key==KEY_F11:Engine.time_scale=.25 if Engine.time_scale==1.0 else 1.0

func legacy_gibs() -> int:
 var total: int=0
 for corpse: Node in service.game.corpses:
  if is_instance_valid(corpse):total+=corpse.severed.size()
 return total
