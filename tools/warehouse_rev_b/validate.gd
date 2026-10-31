extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var arena := preload("res://scripts/warehouse_rev_b.gd").new()
	root.add_child(arena)
	arena.build()
	for i in range(5): await physics_frame
	await create_timer(.4).timeout
	NavigationServer3D.map_force_update(arena.get_world_3d().navigation_map)

	var space := arena.get_world_3d().direct_space_state
	var report: Dictionary = {"engine":Engine.get_version_info()["string"], "navigation_polygons":arena.nav.navigation_mesh.get_polygon_count(), "spawns":[], "routes":[], "doors":[], "errors":[]}
	var origin := arena.nearest_walkable(Vector3(0,0,29))
	for point: Vector3 in arena.spawn_points:
		var path := arena.path_to(point,origin)
		var reached: bool = path.size()>1 and path[-1].distance_to(origin)<.8
		report.spawns.append({"point":str(point),"connected":reached,"path_points":path.size()})
		if not reached: report.errors.append("Unreachable spawn "+str(point))
	for route: Dictionary in arena.PRACTICE_ROUTES:
		var point: Vector3 = route.point
		var closest := arena.nearest_walkable(point)
		var path := arena.path_to(origin,point)
		var reached: bool = closest.distance_to(point)<.7 and path.size()>1 and path[-1].distance_to(point)<.7
		report.routes.append({"name":route.name,"closest":str(closest),"connected":reached,"path_points":path.size(),"end":str(path[-1]) if path.size()>0 else "none"})
		if not reached: report.errors.append("Unreachable route "+str(route.name))
	# Actual standing player capsule swept through every internal opening.
	var capsule := CapsuleShape3D.new()
	capsule.radius = .34
	capsule.height = 1.72
	for door: Dictionary in arena.config.internal_doors:
		var direction := Vector3.RIGHT if door.axis=="x" else Vector3.BACK
		var center := Vector3(door.x,.91,door.z)
		var q := PhysicsShapeQueryParameters3D.new()
		q.shape = capsule
		q.collision_mask = 129
		q.transform = Transform3D(Basis.IDENTITY,center-direction*.65)
		q.motion = direction*1.3
		var result := space.cast_motion(q)
		var clear: bool = result[0]>=.999 and space.intersect_shape(q).is_empty()
		report.doors.append({"center":str(center),"clear":clear,"fraction":result[0]})
		if not clear:report.errors.append("Blocked internal door "+str(center))
	# Full cover blocks bullets; designated shoot-through cover does not.
	for id in ["E-F1","W-P1","M-BR1"]:
		var prop := arena.find_child(id,true,false) as Node3D
		var c := prop.global_position+Vector3.UP*.5
		var move_hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(c-Vector3.BACK*.7,c+Vector3.BACK*.7,128))
		var bullet_hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(c-Vector3.BACK*.7,c+Vector3.BACK*.7,19))
		if move_hit.is_empty() or not bullet_hit.is_empty():report.errors.append("Collision contract "+id)
	var headroom_samples := 0
	var headroom_failures: Array = []
	for r: Dictionary in arena.ramps:
		var a: Vector3 = r.start
		var b: Vector3 = r.finish
		var side := Vector3(-(b-a).z,0,(b-a).x).normalized()
		for i in range(1,20):
			for offset in [-.25,0.0,.25]:
				var foot := a.lerp(b,float(i)/20)+side*offset
				var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(foot+Vector3.UP*.06,foot+Vector3.UP*1.78,129))
				headroom_samples += 1
				if not hit.is_empty():headroom_failures.append(str(foot))
	report["stair_headroom"] = {"samples":headroom_samples,"blocked":headroom_failures}
	if not headroom_failures.is_empty():report.errors.append("Stair headroom blocked")

	var file := FileAccess.open("res://docs/warehouse-rev-b/validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	print("REV_B_VALIDATION ",JSON.stringify(report))
	quit(0 if report.errors.is_empty() else 1)
