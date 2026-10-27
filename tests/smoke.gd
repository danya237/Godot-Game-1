extends SceneTree
## Run: Godot --headless --path . --fixed-fps 120 --script tests/smoke.gd
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
	else:
		print("PASS: " + message)

func _run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await physics_frame
	check(game.npc.position == Vector2(330, 230), "NPC begins at first waypoint")
	for tick in range(1550):
		await physics_frame
	check(game.npc.visited_points >= 4, "NPC reaches all four waypoints")
	check(game.npc.completed_laps >= 1, "NPC completes and repeats its patrol")
	game._toggle_pause()
	await physics_frame
	await physics_frame
	var stopped_at: Vector2 = game.npc.position
	for tick in range(30):
		await physics_frame
	check(game.npc.position == stopped_at, "Pause freezes the NPC")
	game.restart()
	game.player.position = Vector2(350, 330)
	Input.action_press("move_right")
	for tick in range(75):
		await physics_frame
	Input.action_release("move_right")
	check(game.player.position.x < 379, "Player cannot walk through pond")
	game.restart()
	for point: Vector2 in game.PICKUPS:
		game.player.position = point
		await physics_frame
		await physics_frame
	check(game.collected.count(true) == 5, "All five batteries can be collected")
	game.player.position = game.SPAWN
	await physics_frame
	await physics_frame
	check(game.state == "won", "Returning all batteries to base wins")
	game.restart()
	for hit in range(3):
		game.invulnerable = 0.0
		game.player.position = game.npc.position
		await physics_frame
		await physics_frame
	check(game.health == 0 and game.state == "lost", "Three NPC encounters end the game")
	game.restart()
	check(game.health == 3 and game.collected.count(true) == 0 and game.state == "playing", "Restart restores a clean game")
	game.queue_free()
	await process_frame
	print("SMOKE TEST: %d failures" % failures)
	quit(1 if failures else 0)
