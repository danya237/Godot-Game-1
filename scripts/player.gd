extends "res://scripts/actor.gd"
@export var speed := 220.0
var enabled := true

func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed if enabled else Vector2.ZERO
	move_and_slide()
