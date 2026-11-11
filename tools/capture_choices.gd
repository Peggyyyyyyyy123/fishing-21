extends SceneTree
## Dev helper: screenshots of the keep/release flow. Usage: --script res://tools/capture_choices.gd -- <out_dir>

func _initialize() -> void:
	run.call_deferred()

func snap(name: String) -> void:
	for i in range(4):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_out_dir().path_join(name + ".png"))

func run() -> void:
	var controller := load("res://scenes/main.tscn").instantiate() as GameController
	controller.catalog_store = FishCatalogStore.new("res://tools/.preview_catalog.cfg")
	controller.cast_delay_seconds = 0.01
	controller.catch_source_factory = func() -> CatchSource: return FixedCatchSource.new([Fish.new(&"gold_butterflyfish", 3), Fish.new(&"golden_tuna", 21)])
	root.add_child(controller)
	await process_frame
	var view := controller.get_node("GameView") as GameView
	await snap("choice_menu")
	(view.get_node("%StartButton") as Button).pressed.emit()
	await snap("choice_dawn")
	(view.get_node("%CastButton") as Button).pressed.emit()
	await create_timer(0.1).timeout
	await snap("choice_popup")
	(view.get_node("%KeepButton") as Button).pressed.emit()
	view.open_field_guide()
	await snap("choice_catalog")
	(view.get_node("%FieldGuide") as FieldGuideBook).close()
	(view.get_node("%CastButton") as Button).pressed.emit()
	await create_timer(0.1).timeout
	await snap("choice_overflow")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://tools/.preview_catalog.cfg"))
	controller.queue_free()
	await process_frame
	quit()


func _out_dir() -> String:
	var args := OS.get_cmdline_user_args()
	return args[0] if not args.is_empty() else OS.get_user_data_dir()
