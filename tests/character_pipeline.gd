extends SceneTree
var passed: int=0
var failed: int=0
func _initialize() -> void: call_deferred("run")
func check(condition: bool,message: String) -> void:
 if condition:
  passed+=1
  print("PASS ",message)
 else:
  failed+=1
  push_error(message)
func run() -> void:
 var catalog: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/characters/catalog.json")) as Dictionary
 check(catalog.variants.size()==25,"five variants for each of five role definitions")
 var assembly := ZLCharacterAssembly.new()
 root.add_child(assembly)
 for entry: Dictionary in catalog.variants:
  var definition: ZLCharacterVariant=load(String(entry.resource)) as ZLCharacterVariant
  check(not assembly.configure(definition,true),String(definition.variant_id)+" cannot ship missing art")
  check(assembly.configure(definition,false),String(definition.variant_id)+" assembles in review mode")
  check(assembly.skeletons.size()==4 and assembly.skeletons[0].get_bone_count()==72,String(definition.variant_id)+" retains four 72-bone LODs")
 var definition: ZLCharacterVariant=load("res://data/characters/variants/enforcer_standard.tres") as ZLCharacterVariant
 assembly.configure(definition,false)
 var profile: SkeletonProfile=definition.bone_map.profile
 var complete: bool=true
 for i: int in profile.get_bone_size():
  var name: StringName=definition.bone_map.get_skeleton_bone_name(profile.get_bone_name(i))
  complete=complete and assembly.skeletons[0].find_bone(name)>=0
 check(complete,"every humanoid profile bone resolves in imported skeleton")
 var body: MeshInstance3D=assembly.lod_roots[0].find_children("*","MeshInstance3D",true,false)[0] as MeshInstance3D
 var bounds: AABB=body.global_transform*body.get_aabb()
 check(absf(bounds.size.y-1.8)<.001 and absf(bounds.position.y)<.001,"body is 1.80 m and feet are at origin")
 assembly.update_distance(12.5)
 check(assembly.visible_lod==0,"LOD holds inside hysteresis margin")
 assembly.update_distance(13.1)
 check(assembly.visible_lod==1,"LOD switches beyond outward margin")
 assembly.update_distance(11.5)
 check(assembly.visible_lod==1,"LOD holds on inward traversal inside margin")
 assembly.update_distance(10.9)
 check(assembly.visible_lod==0,"LOD returns beyond inward margin")
 assembly.set_lod(3)
 var visible_count: int=0
 for node: Node3D in assembly.lod_roots:
  if node.visible: visible_count+=1
 check(visible_count==1,"exactly one explicit LOD is visible")
 # Use a second copy of the licensed mesh as a binding fixture, never as shipped gear.
 var part := ZLCharacterPart.new()
 part.part_id=&"binding_fixture"
 part.body_shape=definition.body_shape
 part.lod_scenes=definition.body_lods
 var with_part: ZLCharacterVariant=definition.duplicate() as ZLCharacterVariant
 with_part.parts=[part]
 check(assembly.configure(with_part,false),"matching skinned part attaches to shared body skeleton")
 check(assembly.lod_roots[0].find_children("*","Skeleton3D",true,false).size()==1,"part donor skeleton is removed after binding")
 var bound: bool=true
 for node: Node in assembly.lod_roots[0].find_children("*","MeshInstance3D",true,false):
  var mesh: MeshInstance3D=node as MeshInstance3D
  bound=bound and mesh.get_node(mesh.skeleton)==assembly.skeletons[0]
 check(bound,"all assembled mesh skin paths resolve to the same skeleton")
 var camo := ShaderMaterial.new()
 camo.shader=preload("res://scripts/characters/camo_pbr.gdshader")
 part.materials=[camo]
 with_part.parts=[part,part,part]
 check(assembly.configure(with_part,false),"modular gear shares its camo material within the three-material budget")
 check(assembly.material_cache.size()==1,"one camo material instance is shared across parts and LODs")
 check(assembly.material_cache[camo]==camo,"camo material is never duplicated")
 var other := ZLCharacterAssembly.new()
 root.add_child(other)
 var other_variant: ZLCharacterVariant=with_part.duplicate() as ZLCharacterVariant
 other_variant.camo_primary=Color.RED
 check(other.configure(other_variant,false),"second character assembles")
 check(other.material_cache[camo]==assembly.material_cache[camo],"characters share the same material resource")
 var colors_match: bool=true
 for node: Node in other.lod_roots[0].find_children("*","MeshInstance3D",true,false):
  var mesh: MeshInstance3D=node as MeshInstance3D
  if mesh.get_active_material(0)==camo:
   colors_match=colors_match and mesh.get_instance_shader_parameter("primary_color")==Color.RED
 check(colors_match,"character tint is stored on mesh instances")
 var look := ZLCosmeticLook.new()
 look.look_id=&"appearance_fixture"
 look.role=&"enforcer"
 look.base_body_id=&"standard"
 look.camo_id=&"pattern_5"
 look.camo_layer=5
 look.headgear_id=&"helmet_fixture"
 look.head_id=&"head_fixture"
 look.glove_id=&"glove_fixture"
 look.boot_id=&"boot_fixture"
 look.sleeve_id=&"sleeve_fixture"
 look.kit_id=&"kit_fixture"
 with_part.body_materials=[camo]
 look.definition=with_part
 look.skin_tone=Color(.7,.5,.3)
 look.accent=Color.RED
 look.dirt=.4
 look.wear=.2
 check(other.configure_look(look,false),"complete appearance applies in explicit review mode")
 var appearance_matches: bool=true
 for node: Node in other.lod_roots[0].find_children("*","MeshInstance3D",true,false):
  var mesh: MeshInstance3D=node as MeshInstance3D
  if mesh.get_active_material(0)==camo:
   appearance_matches=appearance_matches and mesh.get_instance_shader_parameter("camo_layer")==5 and mesh.get_instance_shader_parameter("skin_tone")==look.skin_tone and mesh.get_instance_shader_parameter("role_accent")==look.accent
 check(appearance_matches,"pattern, skin and role accent stay on each mesh instance")
 check(other.material_cache.size()==1,"body and gear share the same material across all LODs")
 check(other.cosmetic_look.definition.to_data().body_materials.size()==1,"body material bindings survive JSON export")
 look.accent=Color.BLUE
 look.camo_layer=0
 check(other.cosmetic_look.accent==Color.RED and other.cosmetic_look.camo_layer==5,"assembled look snapshots survive later source Resource edits")
 check(other.material_cache[camo]==assembly.material_cache[camo],"full appearance application preserves shared materials")
 look.camo_layer=6
 check(not other.configure_look(look,false) and other.get_child_count()==0,"out-of-range camouflage fails closed and removes stale appearance")
 look.camo_layer=0
 look.role=&"shield"
 check(not other.configure_look(look,false),"appearance cannot use a different role definition")
 other.free()
 part.body_shape=&"broad"
 check(not assembly.configure(with_part,false) and assembly.get_child_count()==0,"mismatched fitted part rejects and rolls back partial assembly")
 part.body_shape=definition.body_shape
 var collision := StaticBody3D.new()
 var packed := PackedScene.new()
 packed.pack(collision)
 collision.free()
 part.lod_scenes=[packed,packed,packed,packed]
 check(not assembly.configure(with_part,false),"cosmetic part cannot add gameplay collision")
 var scripted := Node3D.new()
 scripted.set_script(preload("res://scripts/operator_visual.gd"))
 var script_scene := PackedScene.new()
 script_scene.pack(scripted)
 scripted.free()
 part.lod_scenes=[script_scene,script_scene,script_scene,script_scene]
 check(not assembly.configure(with_part,false),"part scripts are rejected before scene instantiation")
 check(definition.parts.is_empty(),"review edits never mutate shared variant Resource")
 check(definition.to_data().release_blockers.size()>0,"JSON export retains production blockers")
 assembly.free()
 print("CHARACTER PIPELINE RESULT: %d passed, %d failed"%[passed,failed])
 quit(1 if failed else 0)
