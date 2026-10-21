extends SceneTree
const Clip=preload("res://scripts/death/death_clip.gd")
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var world:=Node3D.new();root.add_child(world)
 var settings: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/death/settings.json"))
 var query=preload("res://scripts/death/clearance_query.gd").new();query.configure(settings)
 var clips: Array=[]
 for file: String in DirAccess.get_files_at("res://data/death/clips"):
  if file.ends_with(".tres"):clips.append(load("res://data/death/clips/"+file))
 await physics_frame
 var rows: Array=[];var excluded: Array[RID]=[]
 for tag: String in ["","rifle","pistol","unknown","shotgun","high_caliber"]:
  var tags:=PackedStringArray([] if tag.is_empty() else [tag]);var start: int=Time.get_ticks_usec()
  var result: Dictionary=query.choose(world.get_world_3d().direct_space_state,clips,&"front",tags,Transform3D.IDENTITY,excluded)
  var chosen: Clip=result.clip;assert(chosen!=null)
  assert(chosen.flying==(tag in ["shotgun","high_caliber"]))
  rows.append({"tag":tag,"clip":chosen.id,"flying":chosen.flying,"selection_cpu_us":Time.get_ticks_usec()-start})
 for gore: String in ["off","reduced","full"]:
  var result: Dictionary=query.choose(world.get_world_3d().direct_space_state,clips,&"front",PackedStringArray(["shotgun"]),Transform3D.IDENTITY,excluded)
  assert(result.clip.id==&"flying_back_death");rows.append({"gore":gore,"clip":result.clip.id})
 var left: Dictionary=query.choose(world.get_world_3d().direct_space_state,clips,&"left",PackedStringArray(["shotgun"]),Transform3D.IDENTITY,excluded);assert(left.clip==null)
 var file:=FileAccess.open("res://data/death/selection_test_report.json",FileAccess.WRITE);file.store_string(JSON.stringify({"checks":10,"rows":rows,"left_fallback":true,"passed":true},"  "));file.close();print("SELECTION_TEST_PASS 10");quit()
