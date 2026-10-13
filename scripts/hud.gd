extends Control
## Resolution-independent immediate-mode HUD, with real click targets and focus hints.
var game
var font: Font
var buttons: Array[Dictionary] = []
var hover: String = ""
var clock: float = 0
var ink := Color("e2e8dd")
var muted := Color("8a9d97")
var acid := Color("d4eb85")
var red := Color("e98c74")
var panel := Color(0.038, 0.063, 0.064, 0.94)
var line := Color(0.56, 0.67, 0.61, 0.25)

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	font = ThemeDB.fallback_font
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	clock += delta / maxf(Engine.time_scale, 0.01)
	queue_redraw()

func text(value: String, at: Vector2, size: int = 18, color: Color = Color("e2e8dd")) -> void:
	draw_string(font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func right(value: String, at: Vector2, size: int = 18, color: Color = Color("e2e8dd")) -> void:
	text(value, at - Vector2(font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x, 0), size, color)

func tracked(value: String, at: Vector2, size: int = 13, spacing: float = 3, color: Color = Color("8a9d97")) -> void:
	var x := at.x
	for letter in value:
		text(letter, Vector2(x, at.y), size, color)
		x += font.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + spacing

func rect(at: Vector2, dimensions: Vector2, color: Color) -> void:
	draw_rect(Rect2(at, dimensions), color)

func rule(y: float, x1: float = 48, x2: float = 1392) -> void:
	draw_line(Vector2(x1, y), Vector2(x2, y), line, 1)

func button(id: String, title: String, bounds: Rect2, primary: bool = false, enabled: bool = true) -> void:
	buttons.append({"id": id, "rect": bounds, "enabled": enabled})
	var background := acid if primary else Color(0.09, 0.13, 0.12, 0.94)
	if hover == id and enabled:
		background = background.lightened(0.12)
	if not enabled:
		background = Color(0.07, 0.09, 0.085, 0.9)
	draw_rect(bounds, background)
	draw_rect(bounds, line if not primary else acid, false, 1)
	text(title, bounds.position + Vector2(22, bounds.size.y / 2 + 6), 17, Color("1b2823") if primary else (ink if enabled else muted))
	if primary:
		var tip := bounds.position + Vector2(bounds.size.x - 25, bounds.size.y / 2)
		draw_line(tip - Vector2(19, 0), tip, Color("1b2823"), 2)
		draw_line(tip, tip - Vector2(7, 6), Color("1b2823"), 2)
		draw_line(tip, tip - Vector2(7, -6), Color("1b2823"), 2)

func _draw() -> void:
	if not game or not game.player:
		return
	buttons.clear()
	var viewport := get_viewport_rect().size
	draw_set_transform(Vector2.ZERO, 0, viewport / Vector2(1440, 900))
	match game.state:
		"menu": _menu()
		"combat", "resolve": _combat()
		"shop": _shop()
		"defeat", "complete": _results()
		"paused":
			_combat()
			_pause()

func _brand_header(tag: String) -> void:
	tracked("Z / L", Vector2(48, 53), 20, 4, acid)
	tracked("SANGUINE SYSTEMS", Vector2(153, 51), 12, 2.5, ink)
	right(tag, Vector2(1392, 51), 12, muted)
	rule(76)

func _menu() -> void:
	# Strong left mask preserves the silhouette of the live arena on the right.
	for i in range(40):
		var alpha := 0.90 * (1 - float(i) / 48)
		rect(Vector2(i * 36, 0), Vector2(36, 900), Color(0.025, 0.045, 0.047, alpha))
	rect(Vector2.ZERO, Vector2(1440, 900), Color(0.025, 0.04, 0.04, 0.12))
	_brand_header("RESTRICTED ACCESS    /    BUILD 0.2 · PHASE 1")
	tracked("KINETIC SURVIVAL TRIAL", Vector2(64, 166), 14, 4, acid)
	text("PROJECT:", Vector2(60, 228), 33, ink)
	text("ZERO", Vector2(52, 367), 146, ink)
	text("LINE", Vector2(52, 493), 146, acid)
	rect(Vector2(66, 397), Vector2(338, 5), Color("1c302d"))
	text("Survival is a performance metric.", Vector2(67, 550), 22, ink)
	text("An armed subject. An evolving threat. No safe corners.", Vector2(67, 584), 16, muted)
	button("start", "ENTER THE TRIAL", Rect2(66, 626, 372, 64), true)
	text("[ ENTER ]", Vector2(460, 667), 13, muted)
	button("lab", "MOVEMENT LAB / FREE PRACTICE", Rect2(66, 704, 372, 48))
	text("Three levels. Keep moving. Recover on the run.", Vector2(67, 786), 15, muted)
	# A world-facing dossier, rather than a full-screen black menu.
	rect(Vector2(1046, 132), Vector2(346, 255), panel)
	rect(Vector2(1046, 132), Vector2(3, 255), acid)
	tracked("TEST CHAMBER", Vector2(1070, 163), 12, 2)
	text("K — 17", Vector2(1065, 225), 50, ink)
	rule(246, 1070, 1367)
	text("ENVIRONMENT", Vector2(1070, 276), 12, muted)
	right("INDUSTRIAL", Vector2(1367, 276), 12, ink)
	text("EVALUATION", Vector2(1070, 304), 12, muted)
	right("10 WAVES + ENDLESS", Vector2(1367, 304), 12, ink)
	text("PERSONAL BEST", Vector2(1070, 348), 12, muted)
	right("%06d" % game.best_score, Vector2(1367, 351), 23, acid)
	rect(Vector2(1064, 683), Vector2(12, 12), acid)
	tracked("FACILITY ONLINE", Vector2(1089, 695), 12, 2, acid)
	text("35.6895° N / 139.6917° E", Vector2(1064, 723), 12, muted)
	text("SUBJECT 001    //    AWAITING DEPLOYMENT", Vector2(1064, 749), 11, muted)
	rule(816)
	_settings_footer()

func _settings_footer() -> void:
	text("M  AUDIO " + ("OFF" if game.sound.muted else "ON"), Vector2(48, 850), 12, muted)
	text("G  GORE " + ("ON" if game.gore_enabled else "OFF"), Vector2(222, 850), 12, muted)
	text("H  CAMERA MOTION " + ("ON" if game.camera_motion > 0 else "OFF"), Vector2(390, 850), 12, muted)
	text("[ / ]  SENSITIVITY %.1f" % (game.mouse_sensitivity * 1000), Vector2(668, 850), 12, muted)
	right("GODOT 4.6   /   PLAYABLE PROTOTYPE", Vector2(1392, 850), 12, muted)

func _combat() -> void:
	var p = game.player
	if p.ability == "focus":
		rect(Vector2.ZERO, Vector2(1440, 900), Color(0.25, 0.34, 0.12, 0.09))
		draw_rect(Rect2(8, 8, 1424, 884), Color(acid, 0.4), false, 2)
	elif p.ability == "shroud":
		rect(Vector2.ZERO, Vector2(1440, 900), Color(0.10, 0.35, 0.40, 0.13))
		draw_rect(Rect2(8, 8, 1424, 884), Color("90d6cd"), false, 1)
	if p.hurt > 0:
		for i in range(6):
			draw_rect(Rect2(i * 9, i * 9, 1440 - i * 18, 900 - i * 18), Color(0.78, 0.18, 0.09, p.hurt * 0.17), false, 12)
	if game.pickup_flash > 0:
		draw_rect(Rect2(0, 0, 1440, 900), Color(0.68, 0.84, 0.53, game.pickup_flash), false, 7)
	rect(Vector2(32, 28), Vector2(235, 78), panel)
	tracked("K—17 / LIVE EVALUATION", Vector2(49, 50), 11, 1.5, muted)
	text("MOVEMENT LAB" if game.practice else "WAVE %02d" % game.wave, Vector2(48, 87), 23, ink)
	if not game.practice:
		text("/ " + ("10" if game.wave <= 10 else "END"), Vector2(184, 85), 20, muted)
	else:
		text("%.1f m/s   |   HEIGHT %.1f m   |   T: TARGET + REFILL" % [Vector2(p.velocity.x, p.velocity.z).length(), p.position.y], Vector2(48, 132), 14, acid)
	var total: int = game.enemies.size() + game.queue.size() + game.pending.size()
	rect(Vector2(280, 28), Vector2(155, 78), panel)
	text("THREATS", Vector2(297, 50), 11, muted)
	text("%02d" % total, Vector2(296, 87), 28, acid)
	text("REMAINING", Vector2(344, 84), 10, muted)
	right("%06d" % game.score, Vector2(1400, 66), 34, ink)
	right("STYLE  ×%.2f" % game.combo, Vector2(1400, 92), 13, acid)
	# Compact four-arm reticle; the center stays clear.
	var spread: float = 7 + p.recoil * 80
	for angle in [0, PI / 2, PI, PI * 1.5]:
		var dir := Vector2(cos(angle), sin(angle))
		draw_line(Vector2(720, 450) + dir * spread, Vector2(720, 450) + dir * (spread + 7), Color(ink, 0.9), 1.5)
	if p.hit_timer > 0:
		for angle in [PI / 4, 3 * PI / 4, 5 * PI / 4, 7 * PI / 4]:
			var dir := Vector2(cos(angle), sin(angle))
			draw_line(Vector2(720, 450) + dir * 11, Vector2(720, 450) + dir * 19, acid if p.kill_hit else ink, 2)
	if p.reload_time > 0:
		text("RELOADING", Vector2(677, 501), 12, muted)
		rect(Vector2(674, 514), Vector2(94, 2), line)
		rect(Vector2(674, 514), Vector2(94 * (1 - p.reload_time / p.reload_total), 2), acid)
	if game.message_time > 0:
		var width := font.get_string_size(game.message, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		rect(Vector2(720 - width / 2 - 22, 145), Vector2(width + 44, 45), panel)
		text(game.message, Vector2(720 - width / 2, 174), 16, acid)
	# Vital signs.
	rect(Vector2(32, 755), Vector2(317, 105), panel)
	text("+", Vector2(48, 795), 28, red)
	text("%03d" % ceili(p.health), Vector2(80, 800), 37, ink)
	tracked("VITALS", Vector2(173, 782), 10, 2, muted)
	text("%03d  /  ARMOR" % ceili(p.armor), Vector2(173, 805), 14, Color("a1d0c7"))
	rect(Vector2(50, 822), Vector2(277, 4), line)
	rect(Vector2(50, 822), Vector2(277 * p.health / 100, 4), red if p.health < 35 else acid)
	rect(Vector2(50, 835), Vector2(277, 3), line)
	rect(Vector2(50, 835), Vector2(277 * p.armor / 100, 3), Color("90bfb8"))
	_ability("Q", "FOCUS", p.focus / p.focus_max, Vector2(481, 789), p.ability == "focus", acid)
	_ability("E", "SHROUD", p.shroud / p.shroud_max, Vector2(710, 789), p.ability == "shroud", Color("99d6ce"))
	text("ALT", Vector2(970, 805), 12, muted)
	for i in range(2):
		rect(Vector2(969 + i * 28, 821), Vector2(21, 4), acid if p.dash_charges > i else line)
	rect(Vector2(1135, 755), Vector2(273, 105), panel)
	right(p.weapon().name, Vector2(1390, 779), 12, muted)
	right("%02d" % p.ammo[p.weapon_index], Vector2(1325, 832), 48, acid if p.ammo[p.weapon_index] > 0 else red)
	right("/ " + ("INF" if p.weapon_index == 2 else "%03d" % p.reserve[p.weapon_index]), Vector2(1390, 827), 18, muted)
	text(p.mode, Vector2(50, 887), 10, muted)
	right("WASD  MOVE    SHIFT  SPRINT    C/CTRL  SLIDE    X/ALT  DASH    SPACE  JUMP    R  RELOAD    1/2/3  WEAPON    F  MELEE    ESC  PAUSE", Vector2(1392, 887), 10, muted)
	# Readable grenade indicators stay separate from decorative particles.
	for projectile in game.get_tree().get_nodes_in_group("projectile"):
		if projectile.grenade and not p.camera.is_position_behind(projectile.global_position):
			var pos: Vector2 = p.camera.unproject_position(projectile.global_position) / (get_viewport_rect().size / Vector2(1440, 900))
			pos.x = clampf(pos.x, 40, 1400)
			pos.y = clampf(pos.y, 120, 730)
			draw_circle(pos, 16, Color(red, 0.8))
			text("!", pos + Vector2(-4, 6), 18, Color("1e2724"))

func _ability(key: String, name_text: String, fill: float, pos: Vector2, active: bool, color: Color) -> void:
	rect(pos, Vector2(205, 58), panel)
	draw_rect(Rect2(pos + Vector2(11, 10), Vector2(31, 30)), color if active else muted, false)
	text(key, pos + Vector2(20, 31), 17, color)
	text(name_text, pos + Vector2(54, 25), 12, color if active else ink)
	text("ACTIVE" if active else "%03d%%" % int(fill * 100), pos + Vector2(54, 42), 10, muted)
	rect(pos + Vector2(11, 51), Vector2(183 * clampf(fill, 0, 1), 2), color)

func _shop() -> void:
	rect(Vector2.ZERO, Vector2(1440, 900), Color(0.025, 0.045, 0.043, 0.93))
	_brand_header("INTERMISSION    /    WAVE %02d COMPLETE" % game.wave)
	tracked("RECALIBRATE", Vector2(64, 144), 13, 3, acid)
	text("BUILD YOUR ADVANTAGE.", Vector2(60, 211), 48, ink)
	text("Recovery collected. Reserves restored. The next formation is waiting.", Vector2(64, 251), 18, muted)
	right("%04d CR" % game.credits, Vector2(1376, 207), 40, acid)
	var items := [
		["magazine", "01", "EXTENDED MAGAZINE", "+8 rounds / both primary weapons", 250],
		["brake", "02", "MUZZLE BRAKE", "28% less recoil / immediate control", 200],
		["pickup", "03", "RECOVERY FIELD", "Wider automatic collection radius", 250],
		["capacitor", "04", "FOCUS CAPACITOR", "+20 maximum Focus / longer window", 300],
		["dash", "05", "DASH ACTUATOR", "2.1 second charge / faster recovery", 300]
	]
	for i in items.size():
		var item: Array = items[i]
		var y: float = 306 + i * 79
		rect(Vector2(64, y), Vector2(1312, 67), Color(0.095, 0.13, 0.115, 0.8))
		text(item[1], Vector2(82, y + 41), 22, muted)
		text(item[2], Vector2(143, y + 29), 17, ink)
		text(item[3], Vector2(143, y + 51), 13, muted)
		var owned: bool = item[0] in game.purchased
		button(item[0], "INSTALLED" if owned else "%d CR   /   INSTALL" % item[4], Rect2(1083, y + 9, 276, 49), false, not owned and game.credits >= item[4])
	text(game.shop_message, Vector2(64, 748), 12, acid)
	button("next", "DEPLOY / WAVE %02d" % (game.wave + 1), Rect2(993, 764, 383, 60), true)
	text("[ ENTER ]  CONTINUE", Vector2(64, 805), 14, muted)
	rule(845)
	text("UPGRADES LAST FOR THIS RUN. KEEP MOVING TO RECOVER HEALTH AND ARMOR.", Vector2(64, 876), 11, muted)

func _results() -> void:
	var won: bool = game.state == "complete"
	rect(Vector2.ZERO, Vector2(1440, 900), Color(0.025, 0.045, 0.043, 0.90))
	_brand_header("EVALUATION CONCLUDED")
	tracked("SUBJECT 001 / " + ("QUALIFIED" if won else "SIGNAL LOST"), Vector2(64, 167), 13, 3, acid if won else red)
	text("TRIAL COMPLETE." if won else "ZEROED OUT.", Vector2(58, 277), 82, ink)
	text("The system has recorded your performance.", Vector2(64, 326), 20, muted)
	var stats := [["WAVE REACHED", "%02d" % game.wave], ["STYLE SCORE", "%06d" % game.score], ["ELIMINATIONS", "%03d" % game.kills], ["RECOVERED", "%04d" % int(game.recovered)]]
	for i in stats.size():
		var x: float = 64 + i * 330
		rect(Vector2(x, 391), Vector2(307, 162), panel)
		tracked(stats[i][0], Vector2(x + 22, 425), 11, 2)
		text(stats[i][1], Vector2(x + 20, 510), 53, acid)
	text("TIME IN TRIAL   %02d:%02d" % [int(game.elapsed) / 60, int(game.elapsed) % 60], Vector2(64, 599), 16, muted)
	text("PERSONAL BEST   %06d" % game.best_score, Vector2(64, 632), 16, muted)
	button("next" if won else "start", "ENTER ENDLESS" if won else "REDEPLOY", Rect2(64, 690, 384, 64), true)
	text("[ ENTER ]", Vector2(475, 730), 13, muted)
	if won:
		button("start", "NEW TRIAL", Rect2(1024, 690, 352, 64))
	rule(816)
	_settings_footer()

func _pause() -> void:
	rect(Vector2.ZERO, Vector2(1440, 900), Color(0.025, 0.04, 0.04, 0.91))
	_brand_header("SIMULATION SUSPENDED")
	text("TAKE A BREATH.", Vector2(64, 263), 72, ink)
	text("The facility can wait.", Vector2(67, 306), 20, muted)
	button("resume", "RESUME TRIAL", Rect2(66, 362, 360, 64), true)
	button("restart", "RESTART SESSION", Rect2(66, 448, 360, 60))
	button("menu", "RETURN TO TITLE", Rect2(66, 530, 360, 52))
	var controls := [["W / A / S / D", "MOVE"], ["MOUSE 1 / 2", "FIRE / AIM"], ["SHIFT / C OR CTRL", "SPRINT / SLIDE"], ["SPACE / X OR ALT", "JUMP + WALL RUN / DASH"], ["Q / E", "FOCUS / SHROUD"], ["R / F", "RELOAD / MELEE"], ["1 / 2 / 3", "CARBINE / SHOTGUN / SIDEARM"]]
	tracked("OPERATOR CONTROLS", Vector2(720, 194), 12, 3, acid)
	for i in controls.size():
		var y: float = 247 + i * 49
		text(controls[i][0], Vector2(720, y), 14, ink)
		text(controls[i][1], Vector2(950, y), 13, muted)
	text("Hold jump beside a wall at speed to wall-run.", Vector2(720, 632), 15, muted)
	text("Slide into enemies to stagger them. Run over drops to heal.", Vector2(720, 661), 15, muted)
	rule(816)
	_settings_footer()

func _input(event: InputEvent) -> void:
	if game.state in ["combat", "resolve"]:
		return
	var scale_factor := get_viewport_rect().size / Vector2(1440, 900)
	if event is InputEventMouseMotion:
		hover = ""
		for item in buttons:
			if item.rect.has_point(event.position / scale_factor) and item.enabled:
				hover = item.id
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for item in buttons:
			if item.rect.has_point(event.position / scale_factor) and item.enabled:
				match item.id:
					"start": game.start_run()
					"lab": game.start_run(true)
					"restart": game.start_run(game.practice)
					"menu": game.return_to_menu()
					"next": game.start_wave()
					"resume": game.resume_game()
					_: game.purchase(item.id)
				get_viewport().set_input_as_handled()
				break
