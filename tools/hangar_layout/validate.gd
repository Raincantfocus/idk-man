extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var arena := preload("res://scripts/hangar_layout.gd").new()
	root.add_child(arena)
	arena.build()
	for i in range(5): await physics_frame
	await create_timer(.4).timeout
	NavigationServer3D.map_force_update(arena.get_world_3d().navigation_map)

	var space := arena.get_world_3d().direct_space_state
	var report: Dictionary = {"engine":Engine.get_version_info()["string"], "navigation_polygons":arena.nav.navigation_mesh.get_polygon_count(), "spawns":[], "routes":[], "doors":[], "errors":[]}
	var origin := arena.nearest_walkable(Vector3(0,.05,0))
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
	for door: Dictionary in arena.config.openings:
		if door.type=="window": continue
		var horizontal: bool = absf(float(door.center[1])) in [8.0,16.0] and absf(float(door.center[0]))!=14.0
		var direction := Vector3.BACK if horizontal else Vector3.RIGHT
		var center := arena._point(door.center,.91)
		var q := PhysicsShapeQueryParameters3D.new()
		q.shape = capsule
		q.collision_mask = 129
		q.transform = Transform3D(Basis.IDENTITY,center-direction*.65)
		q.motion = direction*1.3
		var result := space.cast_motion(q)
		var clear: bool = result[0]>=.999 and space.intersect_shape(q).is_empty()
		report.doors.append({"center":str(center),"clear":clear,"fraction":result[0]})
		if not clear:report.errors.append("Blocked internal door "+str(center))
	for room: Dictionary in arena.config.rooms:
		var p := arena._point([(room.bounds[0]+room.bounds[2])/2.0,(room.bounds[1]+room.bounds[3])/2.0],.05)
		var target := arena.nearest_walkable(p)
		var path := arena.path_to(origin,target)
		if path.is_empty() or path[-1].distance_to(target)>.5:report.errors.append("Unreachable room "+room.id)
	var headroom_samples := 0
	var headroom_failures: Array = []
	for r: Dictionary in arena.ramps:
		var a: Vector3 = r.start
		var b: Vector3 = r.finish
		var side := Vector3(-(b-a).z,0,(b-a).x).normalized()
		for i in range(1,20):
			for offset in [-.25,0.0,.25]:
				var foot: Vector3 = a.lerp(b,float(i)/20)+side*offset
				var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(foot+Vector3.UP*.06,foot+Vector3.UP*1.78,129))
				headroom_samples += 1
				if not hit.is_empty():headroom_failures.append(str(foot))
	report["stair_headroom"] = {"samples":headroom_samples,"blocked":headroom_failures}
	if not headroom_failures.is_empty():report.errors.append("Stair headroom blocked")

	var file := FileAccess.open("res://docs/hangar-layout/validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	print("HANGAR_VALIDATION ",JSON.stringify(report))
	quit(0 if report.errors.is_empty() else 1)
