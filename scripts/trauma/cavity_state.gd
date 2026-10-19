extends RefCounted
## Presentation-only cavity progression. It owns no health, rewards or physics.
signal changed(zone: StringName, previous: int, next: int)
enum State { SEALED, SURFACE_DAMAGED, BARRIER_BREACHED, CONTENTS_EXPOSED, SETTLED }
var states: Dictionary={}
var ages: Dictionary={}
var thresholds: PackedFloat32Array
var settle_seconds: float
func configure(ids: PackedStringArray, damage_thresholds: PackedFloat32Array, duration: float) -> void:
 states.clear();ages.clear();thresholds=damage_thresholds;settle_seconds=maxf(duration,0.001)
 for id: String in ids:states[StringName(id)]=State.SEALED;ages[StringName(id)]=0.0
func apply_trauma(id: StringName, accumulated: float) -> void:
 if not states.has(id) or not is_finite(accumulated):return
 var next: int=State.SEALED
 for threshold: float in thresholds:
  if accumulated>=threshold:next+=1
 _advance_state(id,mini(next,State.CONTENTS_EXPOSED))
func advance(world_delta: float) -> void:
 if not is_finite(world_delta) or world_delta<=0:return
 for id: StringName in states:
  if states[id]==State.CONTENTS_EXPOSED:
   ages[id]+=world_delta
   if ages[id]>=settle_seconds:_advance_state(id,State.SETTLED)
func _advance_state(id: StringName, next: int) -> void:
 var old: int=states[id]
 if next<=old:return
 states[id]=next;changed.emit(id,old,next)
