extends Node3D
const Actor=preload("res://scripts/ragdoll/anatomical_actor.gd")
var settings: Dictionary
var actor: Actor
var world: Node3D
var camera: Camera3D
var label: Label
var scenario: String="open"
var tag: String="shotgun"
var direction: String="front"
var pool: RefCounted
var begin_pending: int=0
var preview_mode: bool=false
var show_joint_debug: bool=false
var requested_clip: String="Auto clip"
var preview_clip: Resource
var preview_time: float=0.0
var preview_origin:=Vector3.ZERO
var clip_controls: VBoxContainer
var max_depth: float=0.0
var latest_depth: Dictionary={}
func _ready() -> void:
 settings=JSON.parse_string(FileAccess.get_file_as_string("res://data/ragdoll/settings.json"))
 var environment:=WorldEnvironment.new();environment.environment=Environment.new();environment.environment.background_mode=Environment.BG_COLOR;environment.environment.background_color=Color(.12,.15,.19);environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.environment.ambient_light_energy=.8;add_child(environment)
 var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-40,-30,0);light.light_energy=1.6;add_child(light)
 camera=Camera3D.new();camera.position=Vector3(3,2.3,4.8);camera.fov=48;add_child(camera);camera.look_at(Vector3(0,.9,0));camera.current=true
 var canvas:=CanvasLayer.new();add_child(canvas);var controls:=VBoxContainer.new();controls.position=Vector2(10,10);canvas.process_mode=Node.PROCESS_MODE_ALWAYS;canvas.add_child(controls);label=Label.new();controls.add_child(label);label.add_theme_font_size_override("font_size",14)
 for titles: Array in [["open","wall_touch","wall_20cm","crate","corridor","ledge","stairs"],["rifle","shotgun","high_caliber","front","back","left","right","Restart","Pause","Focus"],["Animation preview","Collision test","Auto clip","Joint debug"]]:
  var row:=HBoxContainer.new();controls.add_child(row)
  for title: String in titles:
   var button:=Button.new();button.text=title;row.add_child(button);button.pressed.connect(func()->void:select(title))
 clip_controls=VBoxContainer.new();controls.add_child(clip_controls)
 restart()
func select(title: String) -> void:
 if title=="Joint debug":show_joint_debug=not show_joint_debug;return
 if title=="Pause":get_tree().paused=not get_tree().paused;return
 if title=="Focus":Engine.time_scale=0.2 if Engine.time_scale==1.0 else 1.0;return
 if title=="Animation preview":preview_mode=true
 elif title=="Collision test":preview_mode=false
 elif title=="Auto clip":requested_clip=title
 elif title.begins_with("Clip: "):
  requested_clip=title.trim_prefix("Clip: ")
 elif title in ["rifle","shotgun","high_caliber"]:tag=title
 elif title in ["front","back","left","right"]:direction=title;requested_clip="Auto clip"
 elif title!="Restart":scenario=title
 get_tree().paused=false
 restart()
func add_box(position: Vector3,size: Vector3,color: Color=Color(.35,.38,.42)) -> void:
 var body:=StaticBody3D.new();body.collision_layer=1;world.add_child(body);body.position=position
 var collider:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=size;collider.shape=shape;body.add_child(collider)
 var mesh:=MeshInstance3D.new();var visual:=BoxMesh.new();visual.size=size;mesh.mesh=visual;var material:=StandardMaterial3D.new();material.albedo_color=color;material.roughness=1;mesh.material_override=material;body.add_child(mesh)
func restart() -> void:
 preview_clip=null;preview_time=0.0
 if world!=null:world.free()
 world=Node3D.new();add_child(world);pool=preload("res://scripts/death/ragdoll_budget.gd").new();pool.configure(settings);max_depth=0
 if scenario=="ledge":add_box(Vector3(0,-.25,-2.4),Vector3(6,.5,5))
 else:add_box(Vector3(0,-.25,0),Vector3(20,.5,20))
 var position:=Vector3.ZERO
 match scenario:
  "wall_touch":add_box(Vector3(0,1,-.37),Vector3(5,2,.3))
  "wall_20cm":add_box(Vector3(0,1,-.57),Vector3(5,2,.3))
  "crate":add_box(Vector3(.5,.45,0),Vector3(.5,.9,.7),Color(.45,.30,.18))
  "corridor":add_box(Vector3(-.55,1,0),Vector3(.3,2,6));add_box(Vector3(.55,1,0),Vector3(.3,2,6))
  "stairs":
   position.y=.3
   for i: int in 3:add_box(Vector3(0,.15+float(i)*.15,float(i)),Vector3(5,.3+float(i)*.3,1))
 actor=Actor.new();world.add_child(actor);actor.position=position;actor.setup(settings,pool);actor.budget_camera_position=camera.global_position;begin_pending=3
 preview_origin=position
 _build_clip_buttons()
func _eligible(clip: Resource) -> bool:
 return not clip.flying or tag in settings.flying_allowed_tags
func _build_clip_buttons() -> void:
 for child: Node in clip_controls.get_children():
  clip_controls.remove_child(child);child.queue_free()
 var row: HBoxContainer
 var count: int=0
 for clip: Resource in actor.clips:
  if count%3==0:row=HBoxContainer.new();clip_controls.add_child(row)
  var action: String="Clip: "+String(clip.id)
  var caption: String=String(clip.id).replace("pro_rifle_pack_","Pack: ").replace("death_from_","").replace("death_crouching_","crouch ").replace("the_","").replace("headshot","HS").replace("_"," ")
  var button:=Button.new();button.text="Clip: "+caption;button.set_meta("action",action);button.disabled=not _eligible(clip)
  button.tooltip_text=String(clip.id)+(" — requires shotgun or high_caliber" if clip.flying else " — play in selected mode")
  row.add_child(button);button.pressed.connect(select.bind(action));count+=1
func _start_preview() -> void:
 var candidates: Array=[]
 for clip: Resource in actor.clips:
  if not _eligible(clip):continue
  if requested_clip!="Auto clip" and String(clip.id)==requested_clip:preview_clip=clip;break
  if String(clip.direction)==direction and not clip.requires_crouch:candidates.append(clip)
 if preview_clip==null and not candidates.is_empty():
  candidates.sort_custom(func(a:Resource,b:Resource)->bool:return a.priority>b.priority if a.priority!=b.priority else String(a.id)<String(b.id))
  preview_clip=candidates[0]
 if preview_clip!=null:
  actor.presentation.position=preview_clip.presentation_offset
  actor.player.play(preview_clip.animation);actor.player.seek(0,true);actor.player.pause()
func _physics_process(_delta: float) -> void:
 if actor==null:return
 if begin_pending>0:
  begin_pending-=1
  if begin_pending==0:
   var directions: Dictionary={"front":Vector3(0,0,-1),"back":Vector3(0,0,1),"left":Vector3(1,0,0),"right":Vector3(-1,0,0)}
   if preview_mode:_start_preview()
   else:
    var crouched: bool=false
    var incoming: Vector3=directions[direction]
    if requested_clip!="Auto clip":
     for clip: Resource in actor.clips:
      if String(clip.id)==requested_clip and _eligible(clip):
       actor.clips=[clip];crouched=clip.requires_crouch;direction=String(clip.direction);incoming=directions[direction];break
    actor.begin_death(incoming,PackedStringArray([tag]),Vector3.ZERO,crouched)
 if begin_pending>0:return
 if preview_mode:
  if preview_clip!=null:
   preview_time=minf(preview_time+_delta,float(preview_clip.duration))
   actor.player.seek(preview_time,true)
   actor.position=preview_origin+actor.global_basis*preview_clip.root_at(preview_time)
   actor.skeleton.force_update_all_bone_transforms()
  label.text="ANIMATION PREVIEW — full clip, collision/ragdoll checks bypassed for inspection\n%s / %s | clip: %s | %.2f / %.2f s\nRestart replays. Clip buttons play immediately. Collision test runs the unapproved ragdoll.\nFlying deaths require shotgun or high_caliber. Preview is not collision or deformation approval." % [scenario,tag,String(preview_clip.id) if preview_clip!=null else "no eligible clip",preview_time,float(preview_clip.duration) if preview_clip!=null else 0.0]
  return
 var points: Dictionary=actor.points();latest_depth={}
 for name: String in points:
  var depth: float=actor.query.penetration(get_world_3d().direct_space_state,name,points[name],actor.excluded).length();latest_depth[name]=depth;max_depth=maxf(max_depth,depth)
 if not show_joint_debug:
  label.text="DEATH PLAYBACK | %s | %s\nState: %s | handoff: %s | animation %.2f s\nCollision checks enabled. Flying deaths require shotgun or high_caliber.\nAnatomy and skin validation remain pending." % [scenario,String(actor.selected.id) if actor.selected!=null else "immediate ragdoll",Actor.State.keys()[actor.state],actor.reason,actor.elapsed]
  return
 label.text="ANATOMICAL RIG — REJECTED CANDIDATE\n%s / %s / %s | clip: %s | handoff: %s\nPeak proxy penetration %.1f mm | joint error %.1f mm | one death %d / handoff %d\nFlying animations: shotgun or explicit high_caliber only. Hardware cost unverified." % [scenario,direction,tag,String(actor.selected.id) if actor.selected!=null else "none",actor.reason,max_depth*1000,actor.joint_error()*1000,actor.lethal_events_received,actor.handoff_count]

 label.text+="\nState: %s | constraint recoveries: %d" % [Actor.State.keys()[actor.state],actor.constraint_recoveries]
 label.text+="\nGuard freezes %d | rejected incoming poses %d | angle excess %.1f deg" % [actor.guard_freezes,actor.guard_missing_snapshot,actor.max_angle_error]
 for name: String in actor.joint_metrics:
  var row: Dictionary=actor.joint_metrics[name];var definition: Dictionary=actor.definitions[name]
  var limits: String=("hinge %.0f..%.0f" % [definition.lower_degrees,definition.upper_degrees]) if definition.joint_kind=="hinge" else ("cone %.0f / %.0f" % [definition.swing,definition.twist])
  label.text+="\n%s: %.2f cm | excess %.1f deg | %s" % [name,float(row.separation_m)*100.,float(row.angle_error_degrees),limits]
