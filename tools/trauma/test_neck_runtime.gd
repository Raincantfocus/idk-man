extends SceneTree
var checks: int=0
func check(ok: bool, message: String) -> void:
 assert(ok,message);checks+=1
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var viewer: Node=(load("res://review.tscn") as PackedScene).instantiate();root.add_child(viewer)
 for i: int in 3:await physics_frame
 viewer.effect.configure(viewer.cap,viewer.settings,91,2,viewer.budget,1)
 check(viewer.budget.total(&"blood_drops")==44,"Global droplet reservation")
 check(viewer.effect.streams.size()==5,"Two arteries, two veins, one optional tracheal emitter")
 viewer.set_process(false)
 var before: float=viewer.effect.elapsed;viewer.effect.advance(0);check(viewer.effect.elapsed==before,"Paused effect clock")
 viewer.effect.advance(.025);check(is_equal_approx(viewer.effect.elapsed-before,.025),"Focus-scaled clock")
 viewer.effect.advance(6);check(viewer.effect.streams.all(func(p: GPUParticles3D) -> bool:return not p.emitting),"Pulses expire")
 viewer.effect.reset();check(viewer.budget.total(&"blood_drops")==0,"Emitter lease cleanup")
 var head: RigidBody3D=viewer.heads.spawn_head(3,2,Transform3D(Basis.IDENTITY,Vector3(0,.4,0)),Vector3(20,0,0),Vector3(20,20,20))
 check(head!=null,"Head spawned")
 for i: int in 3:await physics_frame
 check(head.linear_velocity.length()<4.0,"Launch impulse clamp")
 check(head.angular_velocity.length()<=8.01,"Angular clamp")
 check(head.find_children("*","CollisionShape3D",true,false).size()==1,"One head collider")
 viewer.budget.release_owner(2);check(head.freeze and not head.visible,"Head pooled on owner eviction")
 var same: RigidBody3D=viewer.heads.spawn_head(3,3,Transform3D(Basis.IDENTITY,Vector3(0,.4,0)),Vector3.ZERO,Vector3.ZERO)
 check(head==same,"Reuses same pooled head instance")
 viewer.budget.release_owner(3)
 var fragments: Array=viewer.heads.spawn_head_pop(4,Transform3D(Basis.IDENTITY,Vector3(0,.4,0)),Vector3.UP,7)
 check(fragments.size()==4 and viewer.budget.owner_cost(&"gibs",4)==4,"Four-fragment head-pop limit")
 for i: int in 8:await physics_frame
 for fragment: RigidBody3D in fragments:check(fragment.global_position.is_finite(),"Finite fragment simulation")
 check(viewer.pool_below(Vector3(0,.1,0),77),"Traced pool surface")
 check(viewer.budget.total(&"decals")==1,"Pool consumes decal budget")
 var pool_node: Node3D=viewer.pools.active[0].node
 viewer.pools.advance(0);check(is_zero_approx(float(viewer.pools.active[0].age)),"Paused pool clock")
 viewer.pools.advance(4);check(is_equal_approx(pool_node.scale.x,.32),"Four-second pool growth")
 viewer.budget.release_owner(77);check(not pool_node.visible and viewer.pools.active.is_empty(),"Pool owner eviction")
 check(viewer.pool_below(Vector3(0,.1,0),78) and viewer.pools.active[0].node==pool_node,"Pool instance reuse")
 viewer.budget.set_gore_mode(0);check(viewer.budget.entries.is_empty(),"Gore Off releases leases")
 check(viewer.heads.spawn_head(0,5,Transform3D.IDENTITY,Vector3.UP,Vector3.ZERO)==null,"Gore Off blocks head render")
 viewer.effect.configure(viewer.cap,viewer.settings,91,0,viewer.budget,6);check(viewer.effect.streams.is_empty(),"Gore Off blocks emitters")
 var f:=FileAccess.open("res://runtime_validation.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks_passed":checks,"engine":Engine.get_version_info().string,"physics":ProjectSettings.get_setting("physics/3d/physics_engine"),"gameplay_integration":false},"  "));f.close()
 print("NECK_RUNTIME_TESTS ",checks," passed");quit()
