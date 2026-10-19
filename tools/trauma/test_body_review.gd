extends SceneTree
const Importer=preload("res://scripts/trauma/neck_cap_importer.gd")
const Library=preload("res://scripts/trauma/zone_library.gd")
func _initialize() -> void:
 var importer:=Importer.new();assert(importer.configure("res://manifest.json")==OK)
 assert(importer.manifest.variants.size()==45)
 var ids: Dictionary={};var loads: int=0
 for i: int in importer.manifest.variants.size():
  ids[importer.manifest.variants[i].id]=true
  for lod: int in 3:
   var cap: Node3D=importer.instantiate_cap(i,lod);assert(cap!=null)
   var meshes: Array[Node]=cap.find_children("*","MeshInstance3D",true,false)
   assert(meshes.size()==1)
   assert((meshes[0] as MeshInstance3D).material_override==importer.tissue)
   cap.free();loads+=1
 for zone: Resource in Library.read_all():
  if zone.id in [&"head",&"neck"]:continue
  for weapon: String in zone.cap_variants:
   for id: String in zone.cap_variants[weapon]:assert(ids.has(id),"Missing cap "+id)
 print("BODY_REVIEW_TESTS: ",loads," LOD loads; one shared material; all body Resource cap IDs resolve")
 quit()
