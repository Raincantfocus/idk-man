extends SceneTree
var game
var passed := 0
var failed := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
 if ok: passed += 1; print("PASS ",label)
 else: failed += 1; push_error("FAIL "+label)
func ticks(n: int) -> void:
 for i in n: await physics_frame
func run() -> void:
 game = load("res://scenes/main.tscn").instantiate()
 game.is_test = true
 root.add_child(game)
 game.set_process(false)
 game.start_run(true)
 var arena = game.arena
 game.player.set_physics_process(false)
 for enemy in game.enemies: enemy.set_physics_process(false)
 await ticks(3)
 check(arena.BOUNDS.size==Vector2(60,30),"warehouse matches 60 by 30 footprint")
 check(is_equal_approx(game.player.capsule.shape.radius,.5) and is_equal_approx(game.player.standing_shape.height,1.8),"new-map player uses requested capsule")
 check(arena.lights.size()==6,"six fixed lights stay below dynamic-light budget")
 check(arena.objects.size()>=200,"warehouse manifest instantiates its assemblies and details")
 for i in arena.spawn_points.size():
  var point: Vector3 = arena.spawn_points[i]
  var path: PackedVector3Array = arena.path_to(point,Vector3(0,0,-6))
  check(not path.is_empty(),"spawn %s connects to central floor"%i)
 for i in 4:
  var d: Dictionary = arena.definitions.objects.filter(func(o):return o.name=="slide_ramp_"+str(i))[0]
  var bottom: float = d.rect[1] if d.low>d.high else d.rect[1]+d.rect[3]
  var top: float = d.rect[1]+d.rect[3] if d.low>d.high else d.rect[1]
  var path: PackedVector3Array = arena.path_to(Vector3(d.position[0],0,bottom),Vector3(d.position[0],4.5,top))
  check(not path.is_empty() and absf(path[-1].y-4.5)<.4,"ramp %s has continuous ground-to-catwalk navigation"%i)
 check(not arena.path_to(Vector3(-27,4.5,0),Vector3(0,0,-6)).is_empty(),"office connects through stairwell to combat floor")
 check(arena.objects.runway_1.get_meta("surface_tag")=="WALLRUN_OK","runway advertises wallrun tag")
 check(arena.objects.office_window_wall_0.get_meta("surface_tag")=="NO_GRIP","glass frames reject grip")
 game.wave=1
 game.player.position=Vector3(0,0,0)
 var selected: Dictionary = arena.choose_spawn()
 check(not selected.is_empty() and arena.spawns[selected.index].type in ["east","west"],"early wave chooses a ground breach")
 if not selected.is_empty():
  check(selected.point.distance_to(game.player.position)>=12,"spawn respects 12m exclusion")
  game.player.position=selected.point
  check(not arena.safe_spawn(selected.point),"spawn safety is rechecked when player approaches")
 arena.apply_wave(3)
 check(arena.objects.has("collapsed_shutter"),"wave 3 creates colliding runway obstruction")
 arena.apply_wave(6)
 check(arena.lights[0].light_color.r>arena.lights[0].light_color.g,"wave 6 switches to red emergency light")
 arena.apply_wave(9)
 check(is_equal_approx(arena.objects.pit_panel.position.y,-1.15),"wave 9 lowers actual pit collision")
 check(not arena.path_to(Vector3(0,-1,1.5),Vector3(0,0,-6)).is_empty(),"lowered pit retains enemy escape navigation")
 arena.reset_map()
 check(is_equal_approx(arena.objects.pit_panel.position.y,-.15) and not arena.objects.has("collapsed_shutter"),"restart restores geometry and event state")
 var crane = arena.objects.crane_load_0
 crane.take_damage(30,crane.position)
 check(crane.countdown==3 and is_instance_valid(crane.warning),"shooting crane starts a 3-second marked warning")
 crane._physics_process(2.9)
 check(not crane.spent and crane.position.y==9,"crane cannot drop before warning finishes")
 crane._physics_process(.2)
 check(crane.falling and crane.position.y<9 and not crane.spent,"crane visibly falls after warning")
 for i in 100: crane._physics_process(.02)
 check(crane.spent and crane.position.y==1,"warned crane load becomes floor obstruction")
 arena.reset_map()
 var fuel = arena.objects.fuel_0
 fuel.take_damage(30,fuel.position)
 check(fuel.spent and fuel.collision_layer==0,"shot fuel barrel explodes once")
 game.player.position=arena.objects.health_0.position
 game.player.health=20
 arena._physics_process(.01)
 check(game.player.health==100 and arena.station_use.has("health_0"),"office station heals once per wave")
 game.player.health=30
 arena._physics_process(.01)
 check(game.player.health==30,"used health station cannot be farmed")
 arena.apply_wave(2)
 arena._physics_process(.01)
 check(game.player.health==100,"new wave rearms the station")
 var enemy = game.spawn_enemy("rusher",Vector3(0,0,-6))
 enemy.begin_descent(Vector3(0,14,-6),Vector3(0,.08,-6),3)
 enemy._physics_process(1.5)
 check(enemy.position.y>6 and enemy.position.y<8 and enemy.collision_layer==2,"skylight enemy descends over time")
 enemy._physics_process(1.5)
 check(is_equal_approx(enemy.position.y,.08) and enemy.collision_layer==2,"descent hands off to normal enemy navigation")
 game.start_run(true)
 await ticks(2)
 check(game.arena.map_wave==0 and game.arena.objects.crane_load_0.position.y==9,"redeploy resets hazards and wave events")
 game.player.set_physics_process(false)
 arena.set_physics_process(false)
 game.player.position=Vector3(-12.8,4.55,13.5)
 arena.zip_from=game.player.position
 arena.zip_time=1.5
 await ticks(2)
 for i in 91: arena._physics_process(1.0/60)
 check(game.player.position.distance_to(Vector3(-12.8,.1,4))<.2,"zipline sweeps a full capsule clear of rails, ramps and runway")
 for route in [Vector3(-17,.05,-.3),Vector3(21,.05,.3)]:
  game.player.position=route
  game.player.velocity=Vector3.ZERO
  game.player.rotation.y=PI if route.x<0 else 0
  game.player.set_physics_process(true)
  Input.action_press("forward")
  Input.action_press("sprint")
  await ticks(205)
  Input.action_release("forward")
  Input.action_release("sprint")
  game.player.set_physics_process(false)
  check(game.player.position.y>4.4,"player capsule climbs actual warehouse ramp on side %s"%route.x)
 var children_before: int = arena.get_child_count()
 for i in 3:
  arena.apply_wave(9)
  arena.reset_map()
 check(arena.get_child_count()==children_before,"wave geometry does not accumulate across restarts")
 game.sound.stop_all()
 game.free()
 await process_frame
 print("WAREHOUSE RESULT: %d passed, %d failed"%[passed,failed])
 quit(1 if failed else 0)
