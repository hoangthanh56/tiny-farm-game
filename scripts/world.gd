extends Node2D

const State = preload("res://scripts/farm_state.gd")
const ORIGIN := Vector2(520, 370)
const TILE := 64
const HOME := Vector2(316, 350)
const SHOP := Vector2(1265, 360)
var state: RefCounted
var target := -1
var reachable := false
var clock := 0.0
var trees: Array[Vector2] = [Vector2(125, 170), Vector2(470, 180), Vector2(610, 160),
	Vector2(900, 140), Vector2(1080, 180), Vector2(1460, 200), Vector2(1450, 510),
	Vector2(150, 710), Vector2(350, 900), Vector2(1120, 890), Vector2(1430, 850)]

func _ready() -> void:
	_obstacle(Rect2(215, 224, 200, 90))
	_obstacle(Rect2(1165, 226, 200, 90))
	_obstacle(Rect2(1120, 600, 280, 170))
	for tree in trees:
		_obstacle(Rect2(tree - Vector2(10, 4), Vector2(20, 20)))

func _obstacle(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	body.position = rect.get_center()
	body.add_child(collision)
	add_child(body)

func plot_at(point: Vector2) -> int:
	var local := point - ORIGIN
	if local.x < 0 or local.y < 0 or local.x >= State.COLUMNS * TILE or local.y >= State.ROWS * TILE:
		return -1
	return floori(local.y / TILE) * State.COLUMNS + floori(local.x / TILE)

func plot_center(index: int) -> Vector2:
	return ORIGIN + Vector2(index % State.COLUMNS, floori(float(index) / State.COLUMNS)) * TILE + Vector2.ONE * TILE / 2.0

func _process(delta: float) -> void:
	clock += delta
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1600, 1050), Color("8ba86d"))
	# Deterministic grass details keep the map stable between sessions.
	for i in range(330):
		var p := Vector2((i * 173 + 39) % 1560 + 20, (i * 97 + 13) % 1010 + 20)
		draw_line(p, p + Vector2(3, -5), Color("78975c"), 2)
		if i % 9 == 0:
			draw_circle(p + Vector2(7, -2), 2, Color("e6d8a2"))
	draw_style_box(_box(Color("d4bd8b"), 25), Rect2(278, 320, 62, 500))
	draw_style_box(_box(Color("d4bd8b"), 25), Rect2(280, 740, 1014, 64))
	draw_style_box(_box(Color("d4bd8b"), 25), Rect2(1235, 320, 60, 274))
	draw_style_box(_box(Color("d4bd8b"), 18), Rect2(320, 490, 190, 48))
	# Pond and small animated ripples.
	draw_style_box(_box(Color("b9c495"), 55), Rect2(1100, 580, 320, 210))
	draw_style_box(_box(Color("75aeb2"), 45), Rect2(1120, 600, 280, 170))
	for i in range(5):
		var p := Vector2(1160 + i * 42, 635 + (i % 3) * 37)
		draw_line(p, p + Vector2(23 + sin(clock + i) * 6, 0), Color("abd1c6"), 2)
	_building(Vector2(210, 165), Color("b7654e"), "NHÀ NHỎ", false)
	_building(Vector2(1160, 165), Color("48796e"), "TIỆM HẠT GIỐNG", true)
	for tree in trees:
		_tree(tree)
	# Garden fence leaves wide walkable entrances on every side.
	for x in range(490, 1070, 32):
		_fence(Vector2(x, 340))
		_fence(Vector2(x, 714))
	draw_style_box(_box(Color("6f8550"), 8), Rect2(ORIGIN - Vector2(10, 10), Vector2(532, 340)))
	if state == null:
		return
	for index in range(state.plots.size()):
		var plot: Dictionary = state.plots[index]
		var center := plot_center(index)
		var rect := Rect2(center - Vector2(29, 29), Vector2(58, 58))
		var soil := Color("829c60")
		if plot.tilled:
			soil = Color("79573e") if plot.watered else Color("b3875b")
		draw_style_box(_box(soil, 5), rect)
		if plot.tilled:
			for line in range(3):
				draw_line(center + Vector2(-22, -16 + line * 16), center + Vector2(22, -16 + line * 16), soil.darkened(0.12), 2)
		if plot.crop >= 0:
			_crop(center, plot)
		if plot.watered:
			draw_circle(center + Vector2(20, 19), 3, Color("91d2dc"))
		if index == target:
			draw_rect(rect.grow(2), Color("f7e4a4") if reachable else Color("dd8872"), false, 3)
	_label(Vector2(550, 310), "VƯỜN NHÀ  /  40 Ô ĐẤT", 18, Color("f3eed6"))
	_label(HOME + Vector2(-63, 22), "E · Ngủ qua ngày", 15, Color("344c38"))
	_label(SHOP + Vector2(-65, 22), "E · Mua và bán", 15, Color("344c38"))

func _crop(center: Vector2, plot: Dictionary) -> void:
	var ripe: bool = state.is_ripe(plot)
	var growth: int = plot.growth
	var sway := sin(clock * 2.0 + center.x) * 1.3
	var height := 9.0 + growth * 5.0
	var top := center + Vector2(sway, -height)
	draw_line(center + Vector2(0, 10), top, Color("3e7044"), 4)
	draw_colored_polygon(PackedVector2Array([top + Vector2(0, 10), top + Vector2(-15, 0), top + Vector2(-10, 13)]), Color("507f48"))
	draw_colored_polygon(PackedVector2Array([top + Vector2(0, 12), top + Vector2(15, -2), top + Vector2(11, 14)]), Color("a5bc64"))
	if ripe:
		var color: Color = State.CROPS[plot.crop].color
		if plot.crop == 0:
			draw_colored_polygon(PackedVector2Array([center + Vector2(-9, -6), center + Vector2(9, -6), center + Vector2(0, 17)]), color)
		elif plot.crop == 1:
			for i in range(4):
				draw_circle(top + Vector2(-5, i * 6), 4, color)
				draw_circle(top + Vector2(5, i * 6 - 3), 4, color)
		else:
			draw_circle(center + Vector2(0, 2), 12 if plot.crop == 3 else 9, color)
			draw_line(center + Vector2(0, -8), center + Vector2(0, 12), color.darkened(0.17), 2)
		draw_circle(center + Vector2(20, -20), 3 + sin(clock * 3) * 0.7, Color("ffe5a0"))

func _building(origin: Vector2, roof: Color, title: String, shop: bool) -> void:
	draw_style_box(_box(Color(0.2, 0.26, 0.18, 0.2), 8), Rect2(origin + Vector2(7, 55), Vector2(215, 108)))
	draw_style_box(_box(Color("f0dfb2"), 5), Rect2(origin + Vector2(5, 55), Vector2(200, 95)))
	draw_colored_polygon(PackedVector2Array([origin + Vector2(-12, 63), origin + Vector2(105, -15), origin + Vector2(222, 63)]), roof)
	for x in [30, 143]:
		draw_rect(Rect2(origin + Vector2(x, 82), Vector2(32, 30)), Color("719e9e"))
		draw_rect(Rect2(origin + Vector2(x, 82), Vector2(32, 30)), Color("fff0ce"), false, 3)
		draw_line(origin + Vector2(x + 16, 82), origin + Vector2(x + 16, 112), Color("fff0ce"), 3)
	draw_style_box(_box(Color("7e6048"), 4), Rect2(origin + Vector2(87, 97), Vector2(38, 53)))
	draw_circle(origin + Vector2(115, 123), 2, Color("f3d995"))
	if shop:
		for i in range(8):
			draw_rect(Rect2(origin + Vector2(4 + i * 25, 61), Vector2(25, 15)), Color("dfac74") if i % 2 == 0 else Color("f5e7c3"))
	_label(origin + Vector2(30 if shop else 59, 48), title, 15, Color("fff2d4"))

func _tree(point: Vector2) -> void:
	draw_circle(point + Vector2(7, 7), 30, Color(0.2, 0.3, 0.15, 0.15))
	draw_rect(Rect2(point + Vector2(-7, -37), Vector2(14, 49)), Color("806345"))
	draw_circle(point + Vector2(0, -56), 35, Color("4f784b"))
	draw_circle(point + Vector2(-18, -43), 25, Color("5d8951"))
	draw_circle(point + Vector2(13, -66), 23, Color("709854"))

func _fence(point: Vector2) -> void:
	draw_rect(Rect2(point + Vector2(0, -15), Vector2(5, 24)), Color("d6c391"))
	draw_rect(Rect2(point + Vector2(0, -8), Vector2(33, 5)), Color("c5ac7d"))

func _label(at: Vector2, text: String, size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _box(color: Color, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	return box
