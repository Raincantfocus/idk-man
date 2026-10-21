extends RefCounted
var tuning: Dictionary
var active: Array=[]
var corpses: Array=[]
var evictions: int=0
func configure(settings: Dictionary) -> void:tuning=settings
func reserve(actor: Node3D, camera: Vector3) -> bool:
 active=active.filter(func(item: Node) -> bool:return is_instance_valid(item) and item.is_simulating())
 if active.size()>=int(tuning.max_full_ragdolls):
  active.sort_custom(func(a: Node3D,b: Node3D) -> bool:return a.global_position.distance_squared_to(camera)>b.global_position.distance_squared_to(camera))
  for candidate: Node in active:
   if candidate.freeze_corpse():active.erase(candidate);evictions+=1;break
 var full: bool=active.size()<int(tuning.max_full_ragdolls)
 if full:active.append(actor)
 corpses=corpses.filter(func(item: Node) -> bool:return is_instance_valid(item))
 if not actor in corpses:corpses.append(actor)
 while corpses.size()>int(tuning.max_corpses):
  var oldest: Node=corpses.pop_front();active.erase(oldest);oldest.queue_free()
 return full
