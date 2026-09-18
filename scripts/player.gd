extends CharacterBody2D
## Drawn with native Godot primitives; replace _draw with Sprite2D later.

var enabled := false
var facing := Vector2.DOWN
var walk_time := 0.0
var action_time := 0.0
var action_tool := 0

func _ready() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 12.0
	shape.shape = circle
	add_child(shape)
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 1600
	camera.limit_bottom = 1050
	add_child(camera)
	z_index = 5

func _physics_process(delta: float) -> void:
	var direction := Vector2.ZERO
	if enabled:
		direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction != Vector2.ZERO:
		facing = direction.normalized()
	velocity = direction * 215.0
	move_and_slide()
	position = position.clamp(Vector2(30, 30), Vector2(1570, 1020))
	if direction != Vector2.ZERO:
		walk_time += delta * 13.0
	else:
		walk_time = 0.0
	action_time = maxf(0.0, action_time - delta)
	queue_redraw()

func animate_tool(tool: int) -> void:
	action_tool = tool
	action_time = 0.28

func _draw() -> void:
	var bob := sin(walk_time) * 2.0
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2(0, 8), 18, Color(0.12, 0.23, 0.15, 0.24))
	draw_set_transform(Vector2.ZERO)
	draw_rect(Rect2(-10, -3 + sin(walk_time) * 3, 8, 13), Color("354a56"))
	draw_rect(Rect2(2, -3 - sin(walk_time) * 3, 8, 13), Color("354a56"))
	draw_style_box(_box(Color("e6ad65"), 5), Rect2(-14, -30 + bob, 28, 29))
	draw_rect(Rect2(-9, -23 + bob, 18, 23), Color("4c7985"))
	draw_rect(Rect2(-8, -29 + bob, 4, 16), Color("6d98a0"))
	draw_rect(Rect2(4, -29 + bob, 4, 16), Color("6d98a0"))
	draw_circle(Vector2(-17, -16 + bob), 5, Color("f0c49b"))
	draw_circle(Vector2(17, -16 + bob), 5, Color("f0c49b"))
	draw_circle(Vector2(0, -39 + bob), 13, Color("f0c49b"))
	if facing.y >= 0:
		draw_circle(Vector2(-4 + facing.x * 3, -39 + bob), 1.6, Color("343c38"))
		draw_circle(Vector2(5 + facing.x * 3, -39 + bob), 1.6, Color("343c38"))
	draw_style_box(_box(Color("d5ab65"), 5), Rect2(-13, -57 + bob, 26, 14))
	draw_style_box(_box(Color("f1cc82"), 4), Rect2(-22, -46 + bob, 44, 7))
	if action_time > 0:
		var tip := facing * (32 + sin(action_time * 14) * 12)
		draw_line(Vector2(12, -15), tip, Color("76583d"), 4)
		if action_tool == 2:
			draw_circle(tip, 9, Color("83c8df"))
		else:
			draw_line(tip - Vector2(8, 0), tip + Vector2(8, 0), Color("dce2da"), 6)

func _box(color: Color, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	return box
