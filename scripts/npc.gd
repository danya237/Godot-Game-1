extends "res://scripts/actor.gd"
## NPC-bevegelse: a repeating patrol with a short pause at each waypoint.
## The NPC never reads keyboard input. Change these values in the Inspector.
@export var speed := 115.0
@export var pause_duration := 0.7
@export var waypoints: PackedVector2Array = PackedVector2Array([
	Vector2(330, 230), Vector2(630, 230),
	Vector2(630, 470), Vector2(330, 470)
])
var target_index := 0
var wait_remaining := 0.0
var enabled := true
var completed_laps := 0
var visited_points := 0

func _ready() -> void:
	is_guard = true
	body_color = Color("f4a56c")
	super._ready()
	if not waypoints.is_empty():
		position = waypoints[0]
		target_index = 1 % waypoints.size()

func _physics_process(delta: float) -> void:
	velocity = Vector2.ZERO
	if not enabled or waypoints.is_empty():
		return
	# WAIT: remain still, then continue automatically.
	if wait_remaining > 0.0:
		wait_remaining = maxf(0.0, wait_remaining - delta)
		return
	var target := waypoints[target_index]
	var distance := global_position.distance_to(target)
	# ARRIVE: clamp the last step so the robot cannot overshoot a point.
	if distance <= maxf(speed * delta, 1.0):
		global_position = target
		visited_points += 1
		if target_index == 0:
			completed_laps += 1
		target_index = (target_index + 1) % waypoints.size()
		wait_remaining = pause_duration
		return
	# MOVE: direction * speed gives velocity in pixels per second.
	# move_and_slide() applies the physics timestep internally.
	velocity = global_position.direction_to(target) * speed
	move_and_slide()
