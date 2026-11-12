extends SceneTree
## Dev helper: plays a seeded day and saves screenshots. Usage: --script res://tools/capture_screens.gd -- <out_dir>


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir := args[0] if not args.is_empty() else OS.get_user_data_dir()
	var controller := load("res://scenes/main.tscn").instantiate() as GameController
	controller.cast_delay_seconds = 0.05
	var config := controller.game_config
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	controller.catch_source_factory = func() -> CatchSource: return SeaPoolCatchSource.new(config, rng)
	root.add_child(controller)
	await _settle()
	_save(out_dir + "/0_menu.png")
	(controller.get_node("GameView/%StartButton") as Button).pressed.emit()
	await _settle()
	_save(out_dir + "/1_dawn.png")
	for index in range(3):
		var cast := controller.get_node("GameView/%CastButton") as Button
		if cast.disabled:
			break
		cast.pressed.emit()
		await create_timer(0.2).timeout
		await _settle()
		_save(out_dir + "/%d_cast.png" % (index + 2))
	quit(0)


func _settle() -> void:
	for frame in range(4):
		await process_frame
	await RenderingServer.frame_post_draw


func _save(path: String) -> void:
	root.get_texture().get_image().save_png(path)
	print("saved ", path)
