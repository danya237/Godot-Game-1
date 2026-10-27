extends CharacterBody2D
## Shared appearance and collision shape for the player and the patrol robot.
@export var body_color: Color = Color("78dec7")
var facing := Vector2.DOWN
var walk_time := 0.0
var is_guard := false

func _ready() -> void:
	var shape := CircleShape2D.new()
	shape.radius = 12.0
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	collision_layer = 2
	collision_mask = 1

func _process(delta: float) -> void:
	if velocity.length() > 1.0:
		facing = velocity.normalized()
		walk_time += delta * 12.0
	queue_redraw()

func _draw() -> void:
	var bob := sin(walk_time) * 1.5 if velocity.length() > 1.0 else 0.0
	draw_ellipse_shadow()
	for side in [-1, 1]:
		var step := sin(walk_time + side * PI / 2.0) * 3.0
		draw_style_box(foot_style(), Rect2(side * 7.0 - 4.0, 8.0 + step, 8.0, 9.0))
	draw_style_box(body_style(body_color.darkened(0.35)), Rect2(-15, -17 + bob, 30, 30))
	draw_style_box(body_style(body_color), Rect2(-15, -21 + bob, 30, 28))
	draw_style_box(body_style(Color("17353c")), Rect2(-11, -15 + bob, 22, 12))
	var eye_offset := facing * 2.0
	for side in [-1, 1]:
		draw_circle(Vector2(side * 5, -9 + bob) + eye_offset, 2.2, Color("f4fff2"))
	draw_line(Vector2(0, -22 + bob), Vector2(0, -29 + bob), body_color, 2)
	draw_circle(Vector2(0, -30 + bob), 3, Color("ffcf77") if is_guard else Color("e9fff0"))
	if is_guard:
		draw_rect(Rect2(-5, 2 + bob, 10, 3), Color("fff0bc"))

func draw_ellipse_shadow() -> void:
	draw_set_transform(Vector2(0, 13), 0, Vector2(1, 0.35))
	draw_circle(Vector2.ZERO, 19, Color(0.02, 0.08, 0.08, 0.35))
	draw_set_transform(Vector2.ZERO)

func body_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(7)
	return style

func foot_style() -> StyleBoxFlat:
	return body_style(Color("153239"))
