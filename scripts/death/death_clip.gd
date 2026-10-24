extends Resource
## Cosmetic clip metadata. The authoritative lethal-hit event belongs to gameplay.
@export var presentation_offset: Vector3=Vector3.ZERO
@export var id: StringName
@export var direction: StringName=&"front"
@export var animation: StringName
@export var root_motion_distance: float=0.0
@export var handoff_time: float=0.0
@export var duration: float=0.0
@export var ends_lying: bool=false
@export var flying: bool=false
@export var requires_crouch: bool=false
@export var min_clearance_behind_cm: float=0.0
@export var priority: int=100
@export var key_bones: PackedStringArray=[]
@export var swept_capsule_radius: Dictionary={}
@export var clearance_samples: Array[Dictionary]=[]
@export var root_samples: Array[Dictionary]=[]
func to_dictionary() -> Dictionary:
 return {"presentation_offset":[presentation_offset.x,presentation_offset.y,presentation_offset.z],"id":String(id),"direction":String(direction),"animation":String(animation),"root_motion_distance":root_motion_distance,"handoff_time":handoff_time,"duration":duration,"ends_lying":ends_lying,"flying":flying,"requires_crouch":requires_crouch,"min_clearance_behind_cm":min_clearance_behind_cm,"priority":priority,"key_bones":Array(key_bones),"swept_capsule_radius":swept_capsule_radius,"clearance_samples":clearance_samples,"root_samples":root_samples}
func root_at(time: float) -> Vector3:
 if root_samples.is_empty():return Vector3.ZERO
 var index: int=mini(int(time*60.0),root_samples.size()-1)
 var next: int=mini(index+1,root_samples.size()-1)
 var a: Array=root_samples[index].position;var b: Array=root_samples[next].position
 return Vector3(a[0],a[1],a[2]).lerp(Vector3(b[0],b[1],b[2]),clampf(time*60.0-float(index),0.0,1.0))
