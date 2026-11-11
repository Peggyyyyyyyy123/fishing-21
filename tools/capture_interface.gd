extends SceneTree
const SAVE := "res://tools/.ui_preview.cfg"
var destination: String

func _initialize() -> void:
	destination = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "res://tools"
	run.call_deferred()

func snap(name: String) -> void:
	for i in range(5): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(destination.path_join(name + ".png"))

func run() -> void:
	if OS.get_cmdline_user_args().has("--small"):
		root.mode = Window.MODE_WINDOWED
		root.size = Vector2i(1280, 720)
		await process_frame
		await process_frame
	print("Capture window: ", root.size, " mode: ", root.mode)
	var store := FishCatalogStore.new(SAVE)
	store.save_raw({"sardine": {"count": 8, "best_weight_kg": 3}, "mackerel": {"count": 4, "best_weight_kg": 4}, "red_seabream": {"count": 2, "best_weight_kg": 11}, "moon_angelfish": {"count": 1, "best_weight_kg": 8}}, 2)
	var controller := load("res://scenes/main.tscn").instantiate() as GameController
	controller.catalog_store = store
	controller.cast_delay_seconds = 0.01
	var rng := RandomNumberGenerator.new()
	rng.seed = 18
	controller.catch_source_factory = func() -> CatchSource: return SeaPoolCatchSource.new(controller.game_config, rng)
	root.add_child(controller)
	await process_frame
	var view := controller.get_node("GameView") as GameView
	await snap("redesign_menu")
	(view.get_node("%StartButton") as Button).pressed.emit()
	await snap("redesign_hud")
	(view.get_node("%SeaPanel") as SeaReportPanel).reveal()
	await snap("redesign_sea")
	(view.get_node("%SeaPanel") as SeaReportPanel).hide()
	view.open_field_guide()
	(view.get_node("%FieldGuide") as FieldGuideBook).select(&"moon_angelfish")
	await snap("redesign_book")
	(view.get_node("%FieldGuide") as FieldGuideBook).close()
	(view.get_node("%CastButton") as Button).pressed.emit()
	await create_timer(0.1).timeout
	await snap("redesign_card")
	(view.get_node("%ReleaseButton") as Button).pressed.emit()
	(view.get_node("%ReturnButton") as Button).pressed.emit()
	await snap("redesign_result")
	controller.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	quit()
