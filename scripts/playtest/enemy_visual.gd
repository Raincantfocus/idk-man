extends Node3D
## Presentation adapter. Gameplay remains in enemy.gd; the reviewed ragdoll is unmodified.
const Actor = preload("res://scripts/ragdoll/anatomical_actor.gd")
const Animator = preload("res://scripts/animation/character_animation.gd")
var actor: Node3D
var animator: Node
var runtime: Node
var owner_enemy: Node3D
var look: Resource
var kind: String
var dead: bool = false
var last_state: String = ""
var trauma := preload("res://scripts/trauma/zone_trauma_state.gd").new()
var hit_sequence: int = 0

func setup_live(enemy: Node3D, service: Node) -> void:
 owner_enemy=enemy;runtime=service;kind=enemy.kind
 name="Unpolished_%s_SharedSoldierFallback" % kind
 look=runtime.reserve_look(enemy,kind)
 actor=Actor.new();add_child(actor)
 var config: Dictionary=runtime.rig_settings.duplicate(true);config.mass_role=kind
 actor.setup(config,runtime.ragdoll_budget)
 # Exported resources have .remap files; enumerate the portable manifest, not filesystem suffixes.
 actor.clips.clear()
 for entry: Dictionary in runtime.clip_catalogue:
  actor.clips.append(load("res://data/ragdoll/clips/"+String(entry.id)+".tres"))
 for clip: Resource in actor.clips.duplicate():
  if clip.direction==&"right":
   var fallback: Resource=clip.duplicate();fallback.direction=&"left";actor.clips.append(fallback)
 runtime.log_once("death_left","FALLBACK","Left death uses authored right-side clip, without mirroring; obstruction checks remain enabled")
 actor.collision_layer=0;actor.collision_mask=0;actor.body_collider.disabled=true
 for bone: PhysicalBone3D in actor.physical.values():bone.collision_layer=0;bone.collision_mask=0
 # No uniform body scaling: all five roles currently share the validated review rig.
 animator=Animator.new();add_child(animator)
 animator.configure(actor.skeleton,load("res://data/animation/actorcore_library.res"),load("res://data/animation/animation_profile.tres"))
 trauma.configure(runtime.zone_definitions,int(look.get_meta("seed",1)))
 runtime.apply_look(actor,look)
 runtime.log_once(kind+":model","FALLBACK",kind+": shared review body/fatigues/carrier; role kit, headgear and build swaps unavailable")
 request_state("idle")

func request_state(state: String) -> void:
 if dead or state==last_state:return
 last_state=state
 if state in ["idle","patrol","advance","strafe","cover","flinch","stagger","dash","grenade","bash"]:
  runtime.log_once(kind+":"+state,"FALLBACK",kind+"/"+state+" -> authored hold/run blend (missing dedicated clip)")
 if state=="reload":animator.on_reload()

func update_pose(delta: float, speed: float, staggered: bool) -> void:
 if dead:return
 request_state("stagger" if staggered else "advance" if speed>.2 else "idle")
 animator.advance(delta,speed)
func set_windup(_value: float) -> void:pass
func on_attack() -> void:
 if dead:return
 if kind in ["rusher","shield"]:request_state("bash")
 animator.on_attack()
func resolved_hit(amount: float, point: Vector3, headshot: bool) -> void:
 hit_sequence+=1
 var zone: StringName=&"head" if headshot else &"chest" if point.y-owner_enemy.global_position.y>1.0 else &"abdomen"
 var weapon: StringName=&"shotgun" if runtime.game.player.weapon_index==1 else &"rifle"
 trauma.apply_hit(hit_sequence,zone,amount,weapon,point.distance_to(runtime.game.player.global_position),amount,(point-runtime.game.player.global_position).normalized(),Vector3.UP)
 if runtime.game.gore_level>0:
  runtime.wound(actor,point)
  if trauma.states.get(zone,0)==4:runtime.log_once("sever:"+String(zone),"FALLBACK","New-rig "+String(zone)+" sever -> wound/blood: authored cap-to-skinned-body joining is unapproved; old-enemy toggle retains legacy severing")
 request_state("flinch")
func die(point: Vector3) -> Node3D:
 if dead:return null
 dead=true;animator.freeze_pose()
 actor.reparent(runtime.game,true);actor.add_to_group("corpse")
 actor.set_meta("playtest_look",look);actor.set_meta("role",kind)
 actor.process_mode=Node.PROCESS_MODE_PAUSABLE
 actor.body_collider.disabled=false;actor.collision_mask=int(runtime.rig_settings.collision_mask)
 for bone: PhysicalBone3D in actor.physical.values():
  bone.collision_layer=int(runtime.rig_settings.corpse_layer);bone.collision_mask=int(runtime.rig_settings.collision_mask)
 actor.budget_camera_position=runtime.game.player.camera.global_position
 var direction: Vector3=(point-runtime.game.player.camera.global_position).normalized()
 var tags:=PackedStringArray(["shotgun"]) if runtime.game.player.weapon_index==1 else PackedStringArray()
 runtime.prepare_death_clip(actor,tags)
 if not runtime.forced_clip.is_empty() and actor.clips.size()==1:
  var side: String=String(actor.clips[0].direction)
  direction=actor.global_basis*({"front":Vector3(0,0,-1),"back":Vector3(0,0,1),"right":Vector3(-1,0,0),"left":Vector3(1,0,0)}[side])
 runtime.ensure_ragdoll_slot()
 actor.begin_death(direction,tags,direction*2.2)
 runtime.register_corpse(actor)
 return actor
