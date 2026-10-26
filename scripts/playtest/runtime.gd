extends Node
## Integration service: no damage, score, loot, AI scheduling or gameplay RNG calls.
const Look=preload("res://scripts/characters/cosmetic_look.gd")
var game: Node
var rig_settings: Dictionary
var ragdoll_budget:=preload("res://scripts/death/ragdoll_budget.gd").new()
var zone_definitions: Array=[]
var clip_catalogue: Array=[]
var rng:=RandomNumberGenerator.new()
var sequence: int=0
var last_look: int=-1
var looks: Array[Dictionary]=[]
var logged: Dictionary={}
var new_enemies: bool=true
var forced_clip: String=""
var corpse_nodes: Array[Node]=[]
var wounds: Array[Node]=[]
var palette: Array[Color]=[Color("9b9b91"),Color("737e69"),Color("9b8872"),Color("6e7a80"),Color("807b69"),Color("625c57")]
var shared_materials: Dictionary={}
var blood_budget:=preload("res://scripts/trauma/cosmetic_budget.gd").new()
var pools:=preload("res://scripts/trauma/corpse_blood_pool.gd").new()
var pool_owners: Dictionary={}
var log_file: FileAccess
func setup(owner_game: Node) -> void:
 game=owner_game;get_window().focus_exited.connect(_on_focus_exited);process_mode=Node.PROCESS_MODE_PAUSABLE;rng.seed=778431
 rig_settings=JSON.parse_string(FileAccess.get_file_as_string("res://data/ragdoll/settings.json"));rig_settings.collision_mask=17;rig_settings.prop_mask=0;ragdoll_budget.configure(rig_settings)
 clip_catalogue=JSON.parse_string(FileAccess.get_file_as_string("res://data/ragdoll/clearance_report.json"))
 zone_definitions=preload("res://scripts/trauma/zone_library.gd").read_all()
 new_enemies=bool(ProjectSettings.get_setting("zero_line/playtest/new_enemies",true))
 if OS.is_debug_build():
  log_file=FileAccess.open("user://playtest-events.log",FileAccess.WRITE)
  var debug: Node=load("res://scripts/playtest/debug_tools.gd").new();debug.service=self;add_child(debug)
  if "--playtest-smoke" in OS.get_cmdline_user_args():
   var smoke: Node=load("res://scripts/playtest/export_smoke.gd").new();smoke.game=game;add_child(smoke)
 blood_budget.configure({"budgets":{"decals":96,"gibs":16,"fragments_per_corpse":4,"blood_drops":48}})
 blood_budget.set_gore_mode(game.gore_level)
 add_child(pools)
 pools.setup(blood_budget,load("res://assets/playtest_gore/pool_albedo.png"),load("res://assets/playtest_gore/pool_normal.png"),load("res://assets/playtest_gore/pool_wet_orm.png"),load("res://assets/playtest_gore/pool_dry_orm.png"))
 if not game.is_test:
  var warmup:=preload("res://scripts/playtest/warmup.gd").new();warmup.service=self;add_child(warmup)
 log_once("engine","INFO","Engine "+Engine.get_version_info().string+"; ragdoll files frozen; shader warmup is best effort, hardware hitch budget unverified")
func log_once(key: String,category: String,message: String) -> void:
 if logged.has(key):return
 logged[key]=true
 var line: String=category+" | "+message
 print(line)
 if log_file!=null:log_file.store_line(line);log_file.flush()
func reserve_look(enemy: Node3D,role: String) -> Resource:
 sequence+=1
 looks=looks.filter(func(r: Dictionary)->bool:return is_instance_valid(r.owner.get_ref()))
 var excluded: Array[int]=[last_look]
 for record: Dictionary in looks:
  var other: Node3D=record.owner.get_ref()
  if other.global_position.distance_to(enemy.global_position)<8:excluded.append(record.index)
 var choices: Array[int]=[]
 for i: int in 36:
  if not i in excluded:choices.append(i)
 var index: int=choices[rng.randi_range(0,choices.size()-1)] if not choices.is_empty() else sequence%36
 if choices.is_empty():log_once("look_exhaustion","FALLBACK","36 palette combinations exhausted; cosmetic repeat allowed")
 last_look=index;looks.append({"owner":weakref(enemy),"index":index})
 var look:=Look.new();look.role=StringName(role);look.look_id=StringName("shared_fallback_%d"%index)
 look.base_body_id=&"review_body_fallback";look.camo_id=StringName("palette_%d_not_camo"%index);look.headgear_id=&"bare_fallback"
 look.build=Vector4.ZERO;look.set_meta("palette",index);look.set_meta("seed",sequence+778431)
 return look
func apply_look(actor: Node,look: Resource) -> void:
 var index: int=int(look.get_meta("palette"))
 for mesh: MeshInstance3D in actor.presentation.find_children("*","MeshInstance3D",true,false):
  if not mesh.material_override is ORMMaterial3D:continue
  var source: ORMMaterial3D=mesh.material_override
  var color_id: int=index%6 if "carrier" in String(mesh.name).to_lower() else index/6
  var key: String=source.albedo_texture.resource_path+str(color_id)
  if not shared_materials.has(key):
   var material: ORMMaterial3D=source.duplicate();material.albedo_color=palette[color_id];shared_materials[key]=material
  mesh.material_override=shared_materials[key]
func prepare_death_clip(actor: Node,tags: PackedStringArray) -> void:
 if not OS.is_debug_build() or forced_clip.is_empty():return
 var filtered: Array=actor.clips.filter(func(c: Resource)->bool:return String(c.id)==forced_clip and (not c.flying or tags.has("shotgun") or tags.has("high_caliber")))
 if not filtered.is_empty():
  actor.clips=filtered
  # Direction selection remains in the unchanged actor; an incompatible direction safely falls back.
func ensure_ragdoll_slot() -> void:
 var active: Array=corpse_nodes.filter(func(n)->bool:return is_instance_valid(n) and n.state!=n.State.FROZEN)
 while active.size()>=6:
  var oldest: Node=active.pop_front()
  if not oldest.freeze_corpse():
   corpse_nodes.erase(oldest);oldest.free()
   log_once("airborne_eviction","FALLBACK","Ragdoll cap: oldest unsupported corpse removed instead of adding a seventh simulation")
func register_corpse(actor: Node) -> void:
 corpse_nodes=corpse_nodes.filter(func(n)->bool:return is_instance_valid(n))
 corpse_nodes.append(actor)
 actor.tree_exiting.connect(func() -> void:
  corpse_nodes.erase(actor);ragdoll_budget.active.erase(actor);ragdoll_budget.corpses.erase(actor)
 )
 while corpse_nodes.size()>18:
  var old: Node=corpse_nodes.pop_front();if is_instance_valid(old):old.queue_free()
func wound(actor: Node,point: Vector3) -> void:
 wounds=wounds.filter(func(n)->bool:return is_instance_valid(n))
 # A bone-attached stain is the supported unfinished-zone fallback, never a cut mesh.
 var attached: Array=actor.get_meta("wounds",[]).filter(func(n)->bool:return is_instance_valid(n))
 if attached.size()>=4:return
 var socket:=BoneAttachment3D.new();socket.bone_name="Chest";actor.skeleton.add_child(socket)
 var visual:=MeshInstance3D.new();var quad:=QuadMesh.new();quad.size=Vector2(.09,.09);visual.mesh=quad
 var mat:=StandardMaterial3D.new();mat.albedo_color=Color(.16,.012,.009);mat.roughness=.4;mat.cull_mode=BaseMaterial3D.CULL_DISABLED;visual.material_override=mat
 socket.add_child(visual);visual.global_position=point
 visual.look_at(game.player.camera.global_position,Vector3.UP)
 attached.append(socket);actor.set_meta("wounds",attached);wounds.append(socket)
func set_gore(mode: int) -> void:
 blood_budget.set_gore_mode(mode)
 if mode==0:
  # Legacy caps are attached to fragmented bodies; remove those cosmetic corpses
  # rather than leaving visible cuts after selecting Off.
  for corpse: Node in game.corpses:
   if is_instance_valid(corpse):corpse.queue_free()
  game.corpses.clear()
  for node: Node in wounds:
   if is_instance_valid(node):node.queue_free()
  wounds.clear()
  for group: String in ["blood_drop","blood_stain","gib"]:
   for node: Node in get_tree().get_nodes_in_group(group):node.queue_free()
func _physics_process(delta: float) -> void:
 pools.advance(delta)
 corpse_nodes=corpse_nodes.filter(func(n)->bool:return is_instance_valid(n))
 for actor: Node in corpse_nodes:
  if game.gore_level==0 or actor.state!=actor.State.FROZEN or pool_owners.has(actor.get_instance_id()):continue
  pool_owners[actor.get_instance_id()]=true
  var p: Vector3=actor.physical.Hips.global_position
  var query:=PhysicsRayQueryParameters3D.create(p+Vector3.UP*.2,p-Vector3.UP*2,1)
  var hit: Dictionary=game.get_world_3d().direct_space_state.intersect_ray(query)
  if not hit.is_empty():pools.add_pool(actor.get_instance_id(),hit.position,hit.normal,1)
func clear_corpses() -> void:
 for node: Node in get_tree().get_nodes_in_group("corpse"):node.queue_free()
 corpse_nodes.clear();ragdoll_budget.active.clear();ragdoll_budget.corpses.clear()
 blood_budget.set_gore_mode(0);blood_budget.set_gore_mode(game.gore_level);pool_owners.clear()
func reset_run() -> void:
 clear_corpses();looks.clear();wounds.clear();last_look=-1;sequence=0;rng.seed=778431
func toggle_models() -> void:
 clear_corpses()
 new_enemies=not new_enemies
 for enemy: Node in game.enemies:
  if is_instance_valid(enemy) and enemy.alive:enemy.rebuild_visual()
 log_once("mode:"+str(new_enemies),"INFO","New enemies="+str(new_enemies))

func can_legacy_sever(corpse: Node) -> bool:
 if corpse.severed.size()>=4:return false
 var total: int=0
 for other: Node in game.corpses:
  if is_instance_valid(other):total+=other.severed.size()
 return total<16

func _on_focus_exited() -> void:
 if game.is_playing():game.pause_game()
