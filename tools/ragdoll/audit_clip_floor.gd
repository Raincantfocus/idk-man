extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var tune: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/ragdoll/settings.json"))
 var pool:=preload("res://scripts/death/ragdoll_budget.gd").new();pool.configure(tune)
 var actor:=preload("res://scripts/ragdoll/anatomical_actor.gd").new();root.add_child(actor);actor.setup(tune,pool)
 var rows: Array=[]
 for clip: Resource in actor.clips:
  actor.player.play(clip.animation);actor.player.seek(0,true)
  var first: Dictionary={}
  for name: String in actor.points():first[name]=actor.points()[name].y-float(tune.key_radii[name])
  rows.append({"clip":String(clip.id),"handoff_seconds":clip.handoff_time,"initial_proxy_bottom_y_m":first})
 var file:=FileAccess.open("res://data/ragdoll/clip_floor_report.json",FileAccess.WRITE)
 file.store_string(JSON.stringify({"scope":"Initial animation-pose proxy bottoms against a horizontal floor at y=0; not mesh penetration or a full clip pass", "cases":rows},"  "));file.close()
 print("CLIP_FLOOR_AUDIT ",rows.size());actor.free();quit()
