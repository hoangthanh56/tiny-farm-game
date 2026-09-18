extends SceneTree
## Optional visual check: run with a rendering driver, not --headless.
## Writes only a preview and its own temporary save slot.

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	main.save_path = "user://tiny_farm_preview.json"
	root.add_child(main)
	await process_frame
	main._new_game()
	main.player.position = Vector2(770, 550)
	main.player.get_node("Camera2D").reset_smoothing()
	main.notice.text = ""
	for index in range(24):
		main.state.plots[index] = {"tilled": true, "crop": index % 4,
			"growth": main.State.CROPS[index % 4].days if index < 8 else index % 2,
			"watered": index % 3 != 0}
	for frame in range(8):
		await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://builds"))
	var error := root.get_texture().get_image().save_png("res://builds/preview.png")
	print("Preview result: ", error_string(error))
	main.queue_free()
	await process_frame
	for suffix in ["", ".tmp", ".bak"]:
		var path: String = "user://tiny_farm_preview.json" + suffix
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	quit(error)
