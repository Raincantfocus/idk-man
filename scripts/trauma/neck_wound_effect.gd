extends Node3D
## Clock is supplied in world seconds. Pause passes zero, Focus passes scaled dt.
## This review component never processes a hit or grants a reward.
const Budget=preload("cosmetic_budget.gd")
var ledger: Budget
var lease: int=-1
var config: Dictionary
var active: bool=false
var elapsed: float=0.0
var duration: float=4.0
var phase: float=0.0
var gore_mode: int=2
var streams: Array[GPUParticles3D]=[]
var surfaces: Array[MeshInstance3D]=[]
func configure(cap: Node3D, settings: Dictionary, cosmetic_seed: int, mode: int, budget: Budget, owner_id: int) -> void:
 reset();config=settings;gore_mode=clampi(mode,0,2)
 var rng:=RandomNumberGenerator.new();rng.seed=cosmetic_seed
 duration=rng.randf_range(float(config.arterial_duration_s[0]),float(config.arterial_duration_s[1]));phase=rng.randf_range(0,TAU)
 for node: Node in cap.find_children("*","MeshInstance3D",true,false):surfaces.append(node as MeshInstance3D)
 ledger=budget
 if gore_mode==0:return
 var requested: int=2*int(config.effects.artery_particles_full)+3*int(config.effects.ooze_particles_full) if gore_mode==2 else 2*int(config.effects.artery_particles_reduced)+2*int(config.effects.ooze_particles_reduced)
 lease=ledger.reserve(&"blood_drops",owner_id,requested,stop_streams)
 if lease<0:return
 active=true
 var count: int=0
 for marker: Node in cap.get_children():
  if not marker is Marker3D:continue
  var arterial: bool=String(marker.name).begins_with("carotid")
  var froth: bool=String(marker.name)=="trachea"
  if froth and gore_mode<2:continue
  var particles:=GPUParticles3D.new();particles.name=String(marker.name)+"_blood";particles.position=(marker as Marker3D).position
  particles.amount=int(config.effects.artery_particles_full if arterial else config.effects.ooze_particles_full) if gore_mode==2 else int(config.effects.artery_particles_reduced if arterial else config.effects.ooze_particles_reduced)
  count+=particles.amount;particles.lifetime=float(config.effects.lifetime_s);particles.use_fixed_seed=true;particles.seed=cosmetic_seed+count;particles.local_coords=false
  particles.visibility_aabb=AABB(Vector3(-2,-2,-2),Vector3(4,4,4))
  var process:=ParticleProcessMaterial.new();process.direction=Vector3.UP;process.spread=8 if arterial else 16;process.gravity=Vector3(0,-float(config.effects.gravity_mps2),0)
  process.initial_velocity_min=float(config.effects.arterial_velocity_mps[0] if arterial else config.effects.ooze_velocity_mps[0]);process.initial_velocity_max=float(config.effects.arterial_velocity_mps[1] if arterial else config.effects.ooze_velocity_mps[1])
  process.scale_min=.0015;process.scale_max=.003;process.color=Color(.18,.035,.025,1) if froth else Color(.12,.008,.014,1)
  particles.process_material=process
  var drop:=QuadMesh.new();drop.size=Vector2(.7,1.0)
  var mat:=StandardMaterial3D.new();mat.albedo_color=process.color;mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mat.billboard_mode=BaseMaterial3D.BILLBOARD_PARTICLES;mat.billboard_keep_scale=true
  drop.material=mat;particles.draw_pass_1=drop;add_child(particles);streams.append(particles);particles.emitting=true
 assert(count<=int(config.budgets.blood_drops),"Per-effect droplet allocation exceeded")
func advance(world_delta: float) -> void:
 if world_delta<=0 or not active:return
 elapsed+=world_delta
 for particle: GPUParticles3D in streams:
  var arterial: bool=String(particle.name).begins_with("carotid")
  var pulse: float=pow(maxf(0,sin(elapsed*TAU*float(config.arterial_frequency_hz)+phase)),4)
  particle.amount_ratio=clampf((1-elapsed/duration)*(pulse if arterial else .35),0,1)
  particle.emitting=elapsed<duration
 for mesh: MeshInstance3D in surfaces:
  if not is_instance_valid(mesh):continue
  mesh.set_instance_shader_parameter("age",elapsed)
  mesh.set_instance_shader_parameter("blood_fill",clampf(.25+elapsed*.12,0,.85))
  mesh.set_instance_shader_parameter("wet_front",clampf(elapsed/3.0,0,1))
func stop_streams() -> void:
 for particle: GPUParticles3D in streams:
  if is_instance_valid(particle):particle.emitting=false;particle.free()
 streams.clear()
func reset() -> void:
 if ledger!=null and lease>=0:ledger.release(lease)
 lease=-1;stop_streams();surfaces.clear();elapsed=0.0;active=false
