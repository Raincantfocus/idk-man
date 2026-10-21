extends RefCounted
const Clip=preload("death_clip.gd")
var tuning: Dictionary
var shapes: Dictionary={}
func configure(settings: Dictionary) -> void:
 tuning=settings
 for bone: String in tuning.key_radii:
  var shape:=CapsuleShape3D.new();shape.radius=float(tuning.key_radii[bone]);shape.height=shape.radius*2.0;shapes[bone]=shape
func parameters(bone: String, point: Vector3, excluded: Array[RID]) -> PhysicsShapeQueryParameters3D:
 var query:=PhysicsShapeQueryParameters3D.new();query.shape=shapes[bone];query.transform=Transform3D(Basis.IDENTITY,point);query.margin=float(tuning.query_margin_m);query.collision_mask=int(tuning.collision_mask);query.exclude=excluded;return query
func obstruction(space: PhysicsDirectSpaceState3D, bone: String, from: Vector3, to: Vector3, excluded: Array[RID]) -> bool:
 var query: PhysicsShapeQueryParameters3D=parameters(bone,from,excluded)
 if not space.intersect_shape(query,1).is_empty():return true
 query.motion=to-from
 if query.motion.length_squared()>0.00000001:
  var fractions: PackedFloat32Array=space.cast_motion(query)
  if fractions.size()==2 and fractions[0]<0.999:return true
 query.transform.origin=to;query.motion=Vector3.ZERO
 return not space.intersect_shape(query,1).is_empty()
func clip_clear(space: PhysicsDirectSpaceState3D, clip: Clip, origin: Transform3D, excluded: Array[RID]) -> bool:
 var previous: Dictionary={}
 for sample: Dictionary in clip.clearance_samples:
  # Simulation owns the pose after planned handoff, so only authored motion is swept.
  if float(sample.time)>clip.handoff_time+0.00001:break
  for name: String in clip.key_bones:
   var value: Array=sample.points[name];var point: Vector3=origin*Vector3(value[0],value[1],value[2])
   if obstruction(space,name,previous.get(name,point),point,excluded):return false
   previous[name]=point
 return true
func choose(space: PhysicsDirectSpaceState3D, clips: Array, direction: StringName, tags: PackedStringArray, origin: Transform3D, excluded: Array[RID], crouched: bool=false) -> Dictionary:
 var candidates: Array=[];var rejected: Array=[]
 for clip: Clip in clips:
  if clip.direction!=direction or clip.requires_crouch!=crouched:continue
  if clip.flying:
   var eligible: bool=false
   for tag: String in tuning.flying_allowed_tags:eligible=eligible or tags.has(tag)
   if not eligible:rejected.append({"id":clip.id,"reason":"weapon_not_eligible"});continue
  candidates.append(clip)
 candidates.sort_custom(func(a: Clip,b: Clip) -> bool:return a.priority>b.priority if a.priority!=b.priority else String(a.id)<String(b.id))
 for clip: Clip in candidates:
  if clip_clear(space,clip,origin,excluded):return {"clip":clip,"reason":"clear","rejected":rejected}
  rejected.append({"id":clip.id,"reason":"clearance_blocked"})
 return {"clip":null,"reason":"ragdoll_now","rejected":rejected}
func penetration(space: PhysicsDirectSpaceState3D, bone: String, point: Vector3, excluded: Array[RID]) -> Vector3:
 var contacts: PackedVector3Array=space.collide_shape(parameters(bone,point,excluded),8)
 var correction:=Vector3.ZERO
 for i: int in range(0,contacts.size()-1,2):
  var delta: Vector3=contacts[i+1]-contacts[i]
  if delta.length_squared()>correction.length_squared():correction=delta
 return correction
func supported(space: PhysicsDirectSpaceState3D, points: Dictionary, excluded: Array[RID]) -> bool:
 for bone: String in ["Hips","LeftFoot","RightFoot"]:
  var point: Vector3=points[bone]
  var query:=PhysicsRayQueryParameters3D.create(point+Vector3.UP*0.01,point-Vector3.UP*float(tuning.support_distance_m),int(tuning.world_mask)|int(tuning.prop_mask),excluded)
  if not space.intersect_ray(query).is_empty():return true
 return false
static func hit_direction(actor_basis: Basis, incoming_velocity: Vector3) -> StringName:
 var source: Vector3=actor_basis.inverse()*(-incoming_velocity)
 if absf(source.z)>=absf(source.x):return &"front" if source.z>0.0 else &"back"
 return &"left" if source.x<0.0 else &"right"
