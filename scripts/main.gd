extends Node2D
## Small playable assignment: collect five batteries and return to the station.
const PlayerScript = preload("res://scripts/player.gd")
const PatrolScript = preload("res://scripts/npc.gd")
const PICKUPS: Array[Vector2] = [Vector2(166, 215), Vector2(782, 215), Vector2(790, 514), Vector2(480, 548), Vector2(170, 379)]
const SPAWN := Vector2(140, 530)
const MINT := Color("91e3c0")
const CREAM := Color("f3edd7")
const MUTED := Color("9eb5a6")
var player: CharacterBody2D
var npc: CharacterBody2D
var collected: Array[bool] = [false, false, false, false, false]
var health := 3
var invulnerable := 0.0
var elapsed := 0.0
var state := "playing"
var paused := false
var show_route := true
var font: Font = ThemeDB.fallback_font
var route_button: Button
var pause_button: Button

func _ready() -> void:
	_setup_input()
	_create_walls()
	player = PlayerScript.new()
	player.name = "Player"
	add_child(player)
	npc = PatrolScript.new()
	npc.name = "PatrolNPC"
	add_child(npc)
	player.z_index = 4
	npc.z_index = 4
	_create_controls()
	restart()

func _setup_input() -> void:
	var bindings := {"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT], "move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN]}
	for action: String in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key: int in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)

func _create_walls() -> void:
	for rect: Rect2 in [Rect2(30, 138, 900, 14), Rect2(30, 610, 900, 14), Rect2(30, 138, 14, 486), Rect2(916, 138, 14, 486), Rect2(389, 280, 182, 116)]:
		var wall := StaticBody2D.new()
		wall.position = rect.get_center()
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = rect.size
		collision.shape = shape
		wall.add_child(collision)
		add_child(wall)

func _create_controls() -> void:
	route_button = _button("Rute: PÅ  [P]", Vector2(576, 41), 134)
	route_button.pressed.connect(_toggle_route)
	pause_button = _button("Pause  [Space]", Vector2(720, 41), 155)
	pause_button.pressed.connect(_toggle_pause)
	var reset := _button("Start på nytt  [R]", Vector2(730, 635), 180)
	reset.pressed.connect(restart)

func _button(caption: String, at: Vector2, width: float) -> Button:
	var button := Button.new()
	button.text = caption
	button.position = at
	button.size = Vector2(width, 36)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", CREAM)
	button.add_theme_stylebox_override("normal", _style(Color("24463f"), 9))
	button.add_theme_stylebox_override("hover", _style(Color("356455"), 9))
	button.add_theme_stylebox_override("pressed", _style(Color("42735f"), 9))
	button.z_index = 10
	add_child(button)
	return button

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_R: restart()
			KEY_P: _toggle_route()
			KEY_SPACE: _toggle_pause()

func _toggle_route() -> void:
	show_route = not show_route
	route_button.text = "Rute: %s  [P]" % ("PÅ" if show_route else "AV")

func _toggle_pause() -> void:
	if state == "playing":
		paused = not paused
		pause_button.text = "Fortsett  [Space]" if paused else "Pause  [Space]"

func restart() -> void:
	collected = [false, false, false, false, false]
	health = 3
	state = "playing"
	paused = false
	elapsed = 0.0
	invulnerable = 1.5
	player.position = SPAWN
	npc.position = npc.waypoints[0]
	npc.target_index = 1
	npc.wait_remaining = 0.7
	npc.completed_laps = 0
	npc.visited_points = 0
	pause_button.text = "Pause  [Space]"

func _physics_process(delta: float) -> void:
	var active := state == "playing" and not paused
	player.enabled = active
	npc.enabled = active
	if active:
		elapsed += delta
		invulnerable = maxf(0.0, invulnerable - delta)
		for i in PICKUPS.size():
			if not collected[i] and player.position.distance_to(PICKUPS[i]) < 28:
				collected[i] = true
		if invulnerable <= 0 and player.position.distance_to(npc.position) < 29:
			health -= 1
			player.position = SPAWN
			invulnerable = 2.0
			if health <= 0:
				state = "lost"
		if collected.count(true) == PICKUPS.size() and player.position.distance_to(SPAWN) < 35:
			state = "won"
	player.modulate.a = 0.45 if invulnerable > 0 and fmod(elapsed, 0.2) < 0.1 else 1.0
	queue_redraw()

func _draw() -> void:
	_draw_header()
	_draw_park()
	_draw_route()
	_draw_pickups()
	_draw_footer()
	if state != "playing" or paused:
		_draw_overlay()

func _draw_header() -> void:
	draw_rect(Rect2(0, 0, 960, 680), Color("102b28"))
	_text("01 / GODOT LAB", Vector2(46, 30), 13, MINT)
	_text("PARK PATROL", Vector2(44, 71), 34, CREAM)
	_text("NPC-BEVEGELSE  /  Samle energi. Unngå vakten.", Vector2(46, 99), 15, MUTED)
	draw_line(Vector2(44, 120), Vector2(916, 120), Color("345249"), 1)
	_text("BATTERIER", Vector2(44, 139), 11, MUTED)
	_text("%d / 5" % collected.count(true), Vector2(128, 139), 13, MINT)
	_text("LIV  " + "● ".repeat(health) + "○ ".repeat(3 - health), Vector2(235, 139), 13, Color("efb28c"))
	_text("TID  %02d:%02d" % [int(elapsed) / 60, int(elapsed) % 60], Vector2(427, 139), 13, MUTED)
	var status := "PAUSE" if paused else ("VENTER" if npc != null and npc.wait_remaining > 0 else "PATRULJERER")
	_text("NPC: " + status, Vector2(693, 139), 12, Color("efb28c"))

func _draw_park() -> void:
	_panel(Rect2(32, 150, 896, 468), Color("315a46"), 15)
	# Grass tiles and small plants, fixed positions keep the map deterministic.
	for y in range(160, 606, 24):
		for x in range(44, 916, 24):
			if (x * 7 + y * 11) % 5 == 0:
				draw_line(Vector2(x, y), Vector2(x + 3, y - 4), Color("426c50"), 1)
	# Paths intersect and form a clear rectangular patrol loop.
	_panel(Rect2(91, 199, 774, 62), Color("9aab7f"), 22)
	_panel(Rect2(296, 203, 68, 300), Color("9aab7f"), 20)
	_panel(Rect2(596, 203, 68, 300), Color("9aab7f"), 20)
	_panel(Rect2(112, 440, 729, 62), Color("9aab7f"), 20)
	_panel(Rect2(113, 232, 55, 328), Color("9aab7f"), 20)
	_panel(Rect2(754, 227, 55, 330), Color("9aab7f"), 20)
	_panel(Rect2(127, 519, 670, 50), Color("9aab7f"), 18)
	# Pond is a physical obstacle in the middle of the patrol route.
	_panel(Rect2(380, 271, 200, 134), Color("233f3d"), 20)
	_panel(Rect2(388, 279, 184, 118), Color("4c8884"), 15)
	for i in range(5):
		var wave_x := 409.0 + i * 30.0
		var wave_y := 304.0 + (i % 3) * 28.0
		draw_line(Vector2(wave_x, wave_y), Vector2(wave_x + 18, wave_y), Color("78b1a1"), 2)
	draw_circle(Vector2(539, 367), 9, Color("9bbd74"))
	draw_circle(Vector2(539, 365), 3, Color("f1d5b5"))
	_text("DAMMEN", Vector2(446, 432), 11, Color("b6c9a7"))
	for p: Vector2 in [Vector2(89, 184), Vector2(873, 184), Vector2(877, 585), Vector2(80, 583), Vector2(237, 320), Vector2(713, 354), Vector2(463, 182)]:
		_tree(p)
	for p: Vector2 in [Vector2(226, 566), Vector2(697, 191), Vector2(692, 571), Vector2(230, 185)]:
		_flowers(p)
	# Home station.
	draw_circle(SPAWN, 31, Color("396853"))
	draw_arc(SPAWN, 31, 0, TAU, 48, MINT, 2, true)
	draw_rect(Rect2(SPAWN + Vector2(-11, -10), Vector2(22, 20)), Color("a8dfbe"), false, 2)
	draw_line(SPAWN + Vector2(-16, -10), SPAWN + Vector2(0, -23), MINT, 3)
	draw_line(SPAWN + Vector2(0, -23), SPAWN + Vector2(16, -10), MINT, 3)
	_text("BASE", Vector2(121, 585), 12, CREAM)
	_text("↑ LEVER HER" if collected.count(true) == 5 else "", Vector2(89, 604), 11, MINT)

func _draw_route() -> void:
	if not show_route or npc == null:
		return
	for i in npc.waypoints.size():
		var a: Vector2 = npc.waypoints[i]
		var b: Vector2 = npc.waypoints[(i + 1) % npc.waypoints.size()]
		draw_dashed_line(a, b, Color(0.30, 0.35, 0.24, 0.6), 2, 7)
		draw_circle(a, 10, Color("405744"))
		_text(str(i + 1), a + Vector2(-4, 4), 11, Color("f2d7a3"))
	var target: Vector2 = npc.waypoints[npc.target_index]
	draw_arc(target, 15, 0, TAU, 32, Color("f2bc7f"), 2, true)
	_text("VAKT", npc.position + Vector2(-18, -42), 11, Color("ffe0a8"))

func _draw_pickups() -> void:
	for i in PICKUPS.size():
		if collected[i]:
			continue
		var p := PICKUPS[i] + Vector2(0, sin(elapsed * 3 + i) * 3)
		draw_circle(p, 19, Color(0.79, 0.89, 0.55, 0.16))
		_panel(Rect2(p + Vector2(-8, -11), Vector2(16, 22)), Color("e9d992"), 4)
		draw_rect(Rect2(p + Vector2(-3, -14), Vector2(6, 4)), Color("e9d992"))
		draw_colored_polygon(PackedVector2Array([p + Vector2(1, -7), p + Vector2(-4, 1), p + Vector2(0, 1), p + Vector2(-1, 7), p + Vector2(5, -2), p + Vector2(1, -2)]), Color("5c7146"))

func _draw_footer() -> void:
	_text("W A S D / PILTASTER", Vector2(44, 648), 12, CREAM)
	_text("Beveg deg", Vector2(44, 668), 12, MUTED)
	_text("5 batterier → tilbake til basen", Vector2(260, 648), 14, MINT)
	_text("Vakthold: 4 punkter · 0,7 s pause · automatisk løkke", Vector2(260, 668), 12, MUTED)

func _draw_overlay() -> void:
	draw_rect(Rect2(32, 150, 896, 468), Color(0.035, 0.09, 0.08, 0.8))
	_panel(Rect2(237, 264, 486, 210), Color("193c32"), 18)
	var title := "PARKEN HAR STRØM!" if state == "won" else ("VAKTEN FANT DEG" if state == "lost" else "EN LITEN PAUSE")
	_text(title, Vector2(274, 322), 27, CREAM)
	var subtitle := "Alle 5 batterier levert. Godt jobbet!" if state == "won" else ("Prøv igjen. Følg med på patruljeruten." if state == "lost" else "NPC-en og spilleren står stille.")
	_text(subtitle, Vector2(274, 365), 18, MINT)
	_text("Space: fortsett" if paused else "Trykk R for å spille igjen", Vector2(274, 427), 17, MUTED)

func _tree(p: Vector2) -> void:
	draw_circle(p + Vector2(3, 9), 23, Color("274b3b"))
	draw_rect(Rect2(p + Vector2(-4, 0), Vector2(8, 20)), Color("7b7950"))
	draw_circle(p + Vector2(-8, -9), 17, Color("477756"))
	draw_circle(p + Vector2(9, -12), 18, Color("53875b"))
	draw_circle(p + Vector2(0, -24), 16, Color("629564"))
	draw_line(p + Vector2(-4, -29), p + Vector2(3, -33), Color("85af73"), 3)

func _flowers(p: Vector2) -> void:
	_panel(Rect2(p - Vector2(22, 12), Vector2(44, 24)), Color("274b39"), 8)
	for i in range(4):
		draw_circle(p + Vector2(-15 + i * 10, -3 + (i % 2) * 6), 3.5, Color("e9b48a") if i % 2 else Color("e2d598"))

func _style(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	return style

func _panel(rect: Rect2, color: Color, radius: int) -> void:
	draw_style_box(_style(color, radius), rect)

func _text(value: String, at: Vector2, size: int, color: Color) -> void:
	draw_string(font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
