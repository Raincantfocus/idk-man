extends RefCounted
const Zone=preload("trauma_zone.gd")
static func read_all(folder: String="res://data/trauma") -> Array:
 var catalogue: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(folder.path_join("zone_catalogue.json")))
 var result: Array=[]
 for entry: Dictionary in catalogue.zones:
  var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(folder.path_join(String(entry.id)+"_zone.json")))
  var zone:=Zone.new()
  for key: String in data:
   match key:
    "thresholds":zone.thresholds=PackedFloat32Array(data[key])
    "allowed_weapon_classes":zone.allowed_weapon_classes=PackedStringArray(data[key])
    "child_zones":zone.child_zones=PackedStringArray(data[key])
    _:zone.set(key,data[key])
  result.append(zone)
 return result
