extends SceneTree

const State = preload("res://scripts/farm_state.gd")
const MainScene = preload("res://scenes/main.tscn")
const TEST_SAVE := "user://tiny_farm_automated_test.json"
const UI_SAVE := "user://tiny_farm_ui_test.json"
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + message)

func run() -> void:
	_test_lifecycle()
	_test_guards()
	_test_save()
	await _test_scene()
	for path in [TEST_SAVE, UI_SAVE]:
		for suffix in ["", ".tmp", ".bak"]:
			if FileAccess.file_exists(path + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
	print("Tiny Farm: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func _test_lifecycle() -> void:
	for crop in range(State.CROPS.size()):
		var state := State.new()
		state.buy(crop)
		var cost: int = State.CROPS[crop].buy
		expect(state.money == 80 - cost, "Buying deducts exact seed cost")
		state.work(0, 0, crop)
		state.work(0, 1, crop)
		state.next_day()
		expect(state.plots[0].growth == 0, "Unwatered crop does not grow")
		for day in range(State.CROPS[crop].days):
			state.work(0, 3, crop)
			expect(not state.changed, "Early harvest rejected")
			state.work(0, 2, crop)
			state.work(0, 2, crop)
			expect(not state.changed, "Cannot water twice in one day")
			state.next_day()
			expect(not state.plots[0].watered, "Water resets every morning")
		expect(state.is_ripe(state.plots[0]), "Crop ripens on the correct day")
		state.work(0, 3, crop)
		expect(state.produce[crop] == 1 and state.harvested == 1, "Harvest enters inventory")
		expect(state.plots[0].crop == -1 and state.plots[0].tilled, "Harvest preserves tilled soil")
		state.work(0, 3, crop)
		expect(state.harvested == 1, "Cannot harvest twice")
		state.sell_all()
		expect(state.money == 80 - cost + State.CROPS[crop].sell, "Sale pays exact amount")
		expect(state.sell_value() == 0, "Sold inventory is empty")
		state.sell_all()
		expect(not state.changed, "Cannot sell twice")

func _test_guards() -> void:
	var state := State.new()
	state.money = 0
	var before := state.to_data()
	state.buy(3)
	state.work(0, 1, 0)
	state.work(0, 2, 0)
	state.work(-1, 0, 0)
	state.work(40, 0, 0)
	expect(state.to_data() == before, "Invalid actions do not change resources")
	state.work(0, 0, 0)
	state.work(0, 1, 0)
	before = state.to_data()
	state.work(0, 1, 1)
	state.work(0, 0, 1)
	expect(state.to_data() == before, "Planted crops cannot be overwritten")
	for invalid in [null, {}, {"version": 2}]:
		expect(not State.valid_data(invalid), "Invalid save structure rejected")
	for field in ["money", "day", "harvested"]:
		var bad := state.to_data()
		bad[field] = -1
		expect(not State.valid_data(bad), "Invalid scalar rejected")
	var bad := state.to_data()
	bad.plots[0].crop = 99
	expect(not State.valid_data(bad), "Unknown crop rejected")
	bad = state.to_data()
	bad.seeds = [1, 2]
	expect(not State.valid_data(bad), "Wrong inventory size rejected")
	bad = state.to_data()
	bad.plots[0].growth = 1.5
	expect(not State.valid_data(bad), "Fractional growth rejected")

func _test_save() -> void:
	var state := State.new()
	state.work(3, 0, 0)
	state.work(3, 1, 0)
	state.work(3, 2, 0)
	state.player_position = Vector2(600, 480)
	expect(state.save_game(TEST_SAVE), "Save writes successfully")
	state.next_day()
	expect(state.save_game(TEST_SAVE), "Save safely replaces old file")
	expect(FileAccess.file_exists(TEST_SAVE + ".bak"), "Previous save kept as backup")
	var restored := State.new()
	expect(restored.load_game(TEST_SAVE), "Save loads successfully")
	expect(restored.to_data() == state.to_data(), "Full state round trips through JSON")
	var file := FileAccess.open(TEST_SAVE, FileAccess.WRITE)
	file.store_string('{"version":1,"money":-1}')
	file.close()
	var before := restored.to_data()
	expect(not restored.load_game(TEST_SAVE), "Corrupt save is rejected")
	expect(restored.to_data() == before, "Bad save leaves existing state intact")
	expect(restored.load_game(TEST_SAVE + ".bak"), "Backup remains loadable")

func _test_scene() -> void:
	var main = MainScene.instantiate()
	main.save_path = UI_SAVE
	root.add_child(main)
	await process_frame
	expect(main.overlay.visible and not main.player.enabled, "Title menu blocks movement")
	main._new_game()
	await process_frame
	expect(main.active and main.player.enabled and not main.overlay.visible, "New game starts playable scene")
	var start: Vector2 = main.player.position
	Input.action_press("move_right")
	for frame in range(12):
		await physics_frame
	Input.action_release("move_right")
	expect(main.player.position.x > start.x, "Movement input moves player")
	main.player.position = Vector2(316, 350)
	Input.action_press("move_up")
	for frame in range(24):
		await physics_frame
	Input.action_release("move_up")
	expect(main.player.position.y >= 325, "House collision stops player from walking through wall")
	main.player.position = Vector2(31, 500)
	Input.action_press("move_left")
	for frame in range(4):
		await physics_frame
	Input.action_release("move_left")
	expect(main.player.position.x >= 30, "Player stays inside map bounds")
	main.player.position = Vector2(520, 402)
	main._select_tool(0)
	main._work(39)
	expect(not main.state.plots[39].tilled, "Cannot interact with distant plots")
	main._work(0)
	main._select_tool(1)
	main._work(0)
	main._select_tool(2)
	main._work(0)
	expect(main.state.plots[0].crop == 0 and main.state.plots[0].watered, "UI farming actions reach rules")
	main._show_inventory()
	expect(main.overlay.visible and not main.player.enabled, "Inventory pauses controls")
	main._close_modal()
	main._show_shop()
	expect(not main.overlay.visible, "Shop requires proximity")
	main.player.position = main.World.SHOP
	main._show_shop()
	expect(main.screen == "shop" and main.overlay.visible, "Shop opens at counter")
	main._buy(1)
	expect(main.state.money == 72, "Shop purchases charge coins")
	main._close_modal()
	main._next_day()
	expect(main.state.day == 2 and main.state.plots[0].growth == 1, "Sleeping advances watered crop")
	expect(main._save(false), "Scene saves player and progress")
	main.state.money = 0
	main._load_game()
	expect(main.state.money == 72, "Scene loads saved state")
	main._show_menu()
	expect(not main.player.enabled, "Pause menu blocks player")
	main.queue_free()
	await process_frame
	await create_timer(0.25).timeout
