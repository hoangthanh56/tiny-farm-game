extends Node2D
## Scene coordinator: UI talks to FarmState, while World and Player draw the map.

const State = preload("res://scripts/farm_state.gd")
const World = preload("res://scripts/world.gd")
const Player = preload("res://scripts/player.gd")
const Sound = preload("res://scripts/sound.gd")
const TOOL_NAMES := ["Cuốc đất", "Gieo hạt", "Tưới nước", "Thu hoạch"]

var state := State.new()
var world: Node2D
var player: CharacterBody2D
var sound: AudioStreamPlayer
var ui: Control
var stats: Label
var hint: Label
var notice: Label
var seed_button: Button
var tool_buttons: Array[Button] = []
var overlay: ColorRect
var modal: VBoxContainer
var selected_crop := 0
var selected_tool := 0
var active := false
var screen := ""
var mouse_target := false
var notice_seconds := 0.0
var autosave_seconds := 0.0
var save_path := State.SAVE_PATH
var confirm_new: ConfirmationDialog
var confirm_sleep: ConfirmationDialog

func _ready() -> void:
	_setup_input()
	world = World.new()
	world.state = state
	add_child(world)
	player = Player.new()
	player.position = state.player_position
	add_child(player)
	sound = Sound.new()
	add_child(sound)
	_build_ui()
	get_tree().auto_accept_quit = false
	_show_menu()

func _setup_input() -> void:
	var bindings := {"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN],
		"interact": [KEY_E, KEY_SPACE], "bag": [KEY_I], "shop": [KEY_B],
		"sleep": [KEY_N], "cycle_seed": [KEY_Q], "save_game": [KEY_F5], "load_game": [KEY_F9]}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(ui)
	var theme := Theme.new()
	theme.default_font_size = 16
	for kind in ["normal", "hover", "pressed", "focus", "disabled"]:
		var color := Color("345747")
		if kind == "hover": color = Color("4c7159")
		if kind == "pressed": color = Color("917544")
		if kind == "disabled": color = Color("56655b")
		var box := StyleBoxFlat.new()
		box.bg_color = color
		box.set_corner_radius_all(8)
		box.content_margin_left = 16
		box.content_margin_right = 16
		box.content_margin_top = 10
		box.content_margin_bottom = 10
		if kind == "focus":
			box.bg_color = Color.TRANSPARENT
			box.border_color = Color("ebcb80")
			box.set_border_width_all(2)
		theme.set_stylebox(kind, "Button", box)
	theme.set_color("font_color", "Label", Color("f3ecd7"))
	theme.set_color("font_color", "Button", Color("f3ecd7"))
	ui.theme = theme
	var top := PanelContainer.new()
	_place(top, Control.PRESET_TOP_WIDE, Vector4(18, 16, -18, 77))
	top.add_theme_stylebox_override("panel", _panel_style())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	top.add_child(row)
	var brand := _label("TINY FARM", 23)
	row.add_child(brand)
	stats = _label("", 16)
	stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(stats)
	row.add_child(_button("Túi đồ [I]", _show_inventory))
	row.add_child(_button("Menu [Esc]", _show_menu))
	var help_panel := PanelContainer.new()
	_place(help_panel, Control.PRESET_TOP_LEFT, Vector4(18, 100, 328, 205))
	var help_style := _panel_style()
	help_style.bg_color = Color(0.15, 0.25, 0.20, 0.88)
	help_panel.add_theme_stylebox_override("panel", help_style)
	var help := _label("WASD / Mũi tên: di chuyển\nE / Space: thao tác phía trước\nChuột trái: thao tác ô gần bạn\nNhà: ngủ  ·  Cửa hàng: mua bán", 14)
	help_panel.add_child(help)
	var bottom := PanelContainer.new()
	_place(bottom, Control.PRESET_BOTTOM_WIDE, Vector4(18, -123, -18, -18))
	bottom.add_theme_stylebox_override("panel", _panel_style())
	var box := VBoxContainer.new()
	bottom.add_child(box)
	hint = _label("", 14)
	box.add_child(hint)
	var tools := HBoxContainer.new()
	tools.add_theme_constant_override("separation", 8)
	box.add_child(tools)
	for index in range(TOOL_NAMES.size()):
		var button := _button("%d · %s" % [index + 1, TOOL_NAMES[index]], _select_tool.bind(index))
		button.toggle_mode = true
		tools.add_child(button)
		tool_buttons.append(button)
	seed_button = _button("", _cycle_seed)
	seed_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tools.add_child(seed_button)
	notice = _label("", 17)
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice.add_theme_color_override("font_shadow_color", Color("253c32"))
	notice.add_theme_constant_override("shadow_offset_x", 2)
	notice.add_theme_constant_override("shadow_offset_y", 2)
	_place(notice, Control.PRESET_BOTTOM_WIDE, Vector4(20, -170, -20, -133))
	overlay = ColorRect.new()
	overlay.color = Color(0.08, 0.17, 0.13, 0.88)
	_place(overlay, Control.PRESET_FULL_RECT, Vector4.ZERO)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var modal_panel := PanelContainer.new()
	modal_panel.custom_minimum_size = Vector2(680, 0)
	modal_panel.add_theme_stylebox_override("panel", _panel_style())
	center.add_child(modal_panel)
	modal = VBoxContainer.new()
	modal.add_theme_constant_override("separation", 13)
	modal_panel.add_child(modal)
	confirm_new = ConfirmationDialog.new()
	confirm_new.title = "Bắt đầu nông trại mới?"
	confirm_new.dialog_text = "Tiến trình đang chơi và bản lưu hiện tại sẽ được thay thế."
	confirm_new.ok_button_text = "Chơi mới"
	confirm_new.cancel_button_text = "Hủy"
	confirm_new.confirmed.connect(_new_game)
	ui.add_child(confirm_new)
	confirm_sleep = ConfirmationDialog.new()
	confirm_sleep.title = "Ngủ qua ngày?"
	confirm_sleep.dialog_text = "Cây đã tưới sẽ lớn thêm một giai đoạn.\nCác ô chưa tưới sẽ không lớn."
	confirm_sleep.ok_button_text = "Sang ngày mới"
	confirm_sleep.cancel_button_text = "Để lát nữa"
	confirm_sleep.confirmed.connect(_next_day)
	confirm_sleep.canceled.connect(func(): player.enabled = active and not overlay.visible)
	ui.add_child(confirm_sleep)
	_refresh()

func _place(control: Control, preset: int, offsets: Vector4) -> void:
	ui.add_child(control)
	control.set_anchors_and_offsets_preset(preset)
	control.offset_left = offsets.x
	control.offset_top = offsets.y
	control.offset_right = offsets.z
	control.offset_bottom = offsets.w

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("263f34")
	style.set_corner_radius_all(12)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 15
	style.content_margin_bottom = 15
	return style

func _label(text: String, size: int = 16) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	return label

func _button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(callback)
	return button

func _clear_modal(title: String, description: String) -> void:
	for child in modal.get_children():
		modal.remove_child(child)
		child.queue_free()
	modal.add_child(_label(title, 30))
	modal.add_child(_label(description, 15))
	overlay.show()
	player.enabled = false

func _show_menu() -> void:
	screen = "menu"
	_clear_modal("TINY FARM  /  Nông trại nhỏ", "Một hạt mầm hôm nay. Một khu vườn ngày mai.")
	if active:
		modal.add_child(_button("Tiếp tục chơi", _close_modal))
		modal.add_child(_button("Lưu tiến trình [F5]", func(): _save(true)))
	var load_button := _button("Tải game đã lưu [F9]", _load_game)
	load_button.disabled = not FileAccess.file_exists(save_path)
	modal.add_child(load_button)
	modal.add_child(_button("Bắt đầu nông trại mới", _request_new))
	modal.add_child(_button("Âm thanh: %s" % ("Tắt" if sound.muted else "Bật"), _toggle_sound))
	modal.add_child(_button("Thoát game", _quit_game))
	modal.add_child(_label("1 Cuốc  →  2 Gieo  →  3 Tưới  →  Về nhà ngủ  →  4 Thu hoạch", 14))
	_focus_first()

func _focus_first() -> void:
	for child in modal.get_children():
		if child is Button and not child.disabled:
			child.grab_focus()
			return

func _toggle_sound() -> void:
	sound.muted = not sound.muted
	_show_menu()

func _request_new() -> void:
	if active or FileAccess.file_exists(save_path):
		confirm_new.popup_centered()
	else:
		_new_game()

func _new_game() -> void:
	state = State.new()
	world.state = state
	player.position = state.player_position
	player.get_node("Camera2D").reset_smoothing()
	selected_tool = 0
	selected_crop = 0
	active = true
	_close_modal()
	_refresh()
	_save(false)
	_toast("Chào bạn! Đi sang phải tới ruộng, chọn cuốc (1) rồi bấm vào ô gần mình.")

func _load_game() -> void:
	if not state.load_game(save_path):
		_toast(state.last_error)
		return
	world.state = state
	player.position = state.player_position
	player.get_node("Camera2D").reset_smoothing()
	active = true
	_close_modal()
	_refresh()
	_toast("Đã tải nông trại · Ngày %d." % state.day)

func _close_modal() -> void:
	if not active:
		return
	overlay.hide()
	screen = ""
	player.enabled = true
	var focused := ui.get_viewport().gui_get_focus_owner()
	if focused != null:
		focused.release_focus()

func _show_inventory() -> void:
	if not active:
		return
	screen = "inventory"
	_clear_modal("Túi đồ", "%d xu  ·  Đã thu hoạch %d cây" % [state.money, state.harvested])
	for index in range(State.CROPS.size()):
		var crop: Dictionary = State.CROPS[index]
		modal.add_child(_label("%s   /   %d hạt giống   /   %d nông sản   /   Bán %d xu/cây" % [crop.name, state.seeds[index], state.produce[index], crop.sell]))
	modal.add_child(_label("Đến tiệm hạt giống ở phía đông bắc để mua và bán.", 14))
	modal.add_child(_button("Đóng [Esc / I]", _close_modal))
	_focus_first()

func _show_shop() -> void:
	if not active:
		return
	if player.position.distance_to(World.SHOP) > 115:
		_toast("Đi tới cửa tiệm ở phía đông bắc, rồi nhấn E hoặc B.")
		return
	screen = "shop"
	_clear_modal("Tiệm hạt giống", "Ví: %d xu  ·  Tưới mỗi ngày, cây sẽ lớn sau mỗi đêm." % state.money)
	for index in range(State.CROPS.size()):
		var crop: Dictionary = State.CROPS[index]
		var row := HBoxContainer.new()
		var label := _label("%s · %d ngày · Bán %d xu · Còn %d hạt" % [crop.name, crop.days, crop.sell, state.seeds[index]], 15)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var buy_button := _button("Mua · %d xu" % crop.buy, _buy.bind(index))
		buy_button.disabled = state.money < crop.buy
		row.add_child(buy_button)
		modal.add_child(row)
	var sell_button := _button("Bán toàn bộ nông sản · %d xu" % state.sell_value(), _sell)
	sell_button.disabled = state.sell_value() == 0
	modal.add_child(sell_button)
	modal.add_child(_button("Rời cửa hàng [Esc / B]", _close_modal))
	_focus_first()

func _buy(index: int) -> void:
	_toast(state.buy(index))
	if state.changed:
		sound.effect(4)
		_save(false)
	_refresh()
	_show_shop()

func _sell() -> void:
	_toast(state.sell_all())
	if state.changed:
		sound.effect(4)
		_save(false)
	_refresh()
	_show_shop()

func _select_tool(index: int) -> void:
	selected_tool = index
	_refresh()
	_release_focus()

func _cycle_seed() -> void:
	selected_crop = (selected_crop + 1) % State.CROPS.size()
	selected_tool = 1
	_refresh()
	_release_focus()

func _release_focus() -> void:
	var focused := ui.get_viewport().gui_get_focus_owner()
	if focused != null:
		focused.release_focus()

func _refresh() -> void:
	stats.text = "Ngày %02d   /   %d xu   /   %d cây thu hoạch" % [state.day, state.money, state.harvested]
	seed_button.text = "Q · %s (%d hạt)" % [State.CROPS[selected_crop].name, state.seeds[selected_crop]]
	for index in range(tool_buttons.size()):
		tool_buttons[index].set_pressed_no_signal(index == selected_tool)

func _process(delta: float) -> void:
	if notice_seconds > 0:
		notice_seconds -= delta
		if notice_seconds <= 0:
			notice.text = ""
	if not active or overlay.visible or confirm_sleep.visible:
		world.target = -1
		return
	if player.velocity.length() > 0:
		mouse_target = false
	var point: Vector2 = world.get_global_mouse_position() if mouse_target else player.position + player.facing * 44
	world.target = world.plot_at(point)
	world.reachable = world.target >= 0 and player.position.distance_to(world.plot_center(world.target)) <= 105
	if player.position.distance_to(World.HOME) <= 115:
		hint.text = "NHÀ NHỎ  ·  Nhấn E hoặc N để ngủ và sang ngày mới."
	elif player.position.distance_to(World.SHOP) <= 115:
		hint.text = "TIỆM HẠT GIỐNG  ·  Nhấn E hoặc B để mua hạt và bán nông sản."
	elif world.target >= 0:
		var plot: Dictionary = state.plots[world.target]
		var description := "Đã cuốc" if plot.tilled else "Đất chưa cuốc"
		if plot.crop >= 0:
			description = "%s · %d/%d ngày · %s" % [State.CROPS[plot.crop].name, plot.growth, State.CROPS[plot.crop].days, "CHÍN" if state.is_ripe(plot) else ("Đã tưới" if plot.watered else "Cần nước")]
		hint.text = "%s  /  %s" % [description, "E hoặc bấm chuột để " + TOOL_NAMES[selected_tool].to_lower() if world.reachable else "Đi lại gần ô đất"]
	else:
		hint.text = "Ruộng ở giữa vườn  ·  Nhà bên trái  ·  Cửa hàng bên phải  ·  I mở túi đồ"
	autosave_seconds += delta
	if autosave_seconds >= 20:
		autosave_seconds = 0
		_save(false)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if confirm_sleep.visible or confirm_new.visible:
		return
	if event.is_action_pressed("ui_cancel"):
		if overlay.visible and active:
			_close_modal()
		else:
			_show_menu()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("load_game"):
		_load_game()
		return
	if not active:
		return
	if event.is_action_pressed("save_game"):
		_save(true)
		return
	if overlay.visible:
		if (screen == "inventory" and event.is_action_pressed("bag")) or (screen == "shop" and event.is_action_pressed("shop")):
			_close_modal()
		return
	if event.is_action_pressed("bag"):
		_show_inventory()
	elif event.is_action_pressed("shop"):
		_show_shop()
	elif event.is_action_pressed("sleep"):
		_request_sleep()
	elif event.is_action_pressed("cycle_seed"):
		_cycle_seed()
	elif event is InputEventKey and event.pressed and event.physical_keycode >= KEY_1 and event.physical_keycode <= KEY_4:
		_select_tool(event.physical_keycode - KEY_1)
	elif event is InputEventMouseMotion:
		mouse_target = true
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_work(world.plot_at(world.get_global_mouse_position()))
	elif event.is_action_pressed("interact"):
		if player.position.distance_to(World.HOME) <= 115:
			_request_sleep()
		elif player.position.distance_to(World.SHOP) <= 115:
			_show_shop()
		else:
			_work(world.plot_at(player.position + player.facing * 44))

func _work(index: int) -> void:
	if index < 0:
		_toast("Đứng gần ruộng và hướng về ô đất muốn chăm sóc.")
		return
	if player.position.distance_to(world.plot_center(index)) > 105:
		_toast("Ô đất ở xa quá. Đi lại gần thêm nhé!")
		return
	_toast(state.work(index, selected_tool, selected_crop))
	if state.changed:
		player.animate_tool(selected_tool)
		sound.effect(selected_tool)
		_save(false)
	_refresh()

func _request_sleep() -> void:
	if player.position.distance_to(World.HOME) > 115:
		_toast("Về cửa nhà bên trái khu ruộng để ngủ nhé.")
		return
	player.enabled = false
	confirm_sleep.popup_centered()

func _next_day() -> void:
	var grown: int = state.next_day()
	player.position = World.HOME + Vector2(0, 28)
	player.enabled = true
	sound.effect(4)
	_refresh()
	_toast("Chào ngày %d! %d cây đã lớn. Nhớ tưới lại hôm nay." % [state.day, grown])
	_save(false)

func _save(show_message: bool) -> bool:
	if not active:
		return false
	state.player_position = player.position
	var success: bool = state.save_game(save_path)
	if not success:
		_toast(state.last_error)
	elif show_message:
		_toast("Đã lưu nông trại thành công.")
	return success

func _toast(message: String) -> void:
	notice.text = message
	notice_seconds = 5.5
	# Notifications remain visible above menus and dialogs.
	notice.z_index = 10

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_quit_game()

func _quit_game() -> void:
	if active and not _save(false):
		return
	get_tree().quit()
