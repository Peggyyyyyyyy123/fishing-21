extends SceneTree
const SAVE := "res://tests/.interface_catalog.cfg"
var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, reason: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(reason)

func verify_english(node: Node) -> void:
	var value := ""
	if node is Label or node is Button or node is RichTextLabel: value = node.text
	var english := true
	for i in range(value.length()):
		var code := value.unicode_at(i)
		if code >= 0x3400 and code <= 0x9fff: english = false
	if not value.is_empty(): check(english, "No Chinese text in runtime UI: " + value)
	for child in node.get_children(): verify_english(child)

func run() -> void:
	var c := load("res://config/default_game_config.tres") as GameConfig
	check(ProjectSettings.get_setting("display/window/size/mode") == 3, "Fullscreen startup configured")
	check(c.daily_quotas.slice(0,3) == [180,210,240], "Rent remains unchanged")
	var store := FishCatalogStore.new(SAVE)
	check(store.save_raw({"sardine": true}) == OK, "Prepare legacy boolean save")
	var controller := load("res://scenes/main.tscn").instantiate() as GameController
	controller.catalog_store = store
	controller.cast_delay_seconds = 0.01
	controller.catch_source_factory = func() -> CatchSource: return FixedCatchSource.new([Fish.new(&"sardine", 3), Fish.new(&"golden_tuna", 21)])
	root.add_child(controller)
	await process_frame
	var view := controller.get_node("GameView") as GameView
	check(view.get_node("%MenuOverlay").visible, "Menu opens")
	view.open_field_guide()
	(view.get_node("%FieldGuide") as FieldGuideBook).select(&"sardine")
	check(view.get_node("%CatalogFishStats").text.contains("Not recorded"), "Legacy save does not invent historical best weight")
	check(view.get_node("%CatalogDetails").text.contains("Collected 1 / 10"), "Legacy unlock remains collected")
	check(view.get_node("%CatalogGrid").get_child_count() == 10, "Collection has ten cells")
	check(not (view.get_node("%CatalogGrid").get_child(0) as Button).disabled, "Collected species selectable")
	check((view.get_node("%CatalogGrid").get_child(1) as Button).disabled, "Uncollected silhouette cannot reveal details")
	(view.get_node("%FieldGuide") as FieldGuideBook).close()
	(view.get_node("%StartButton") as Button).pressed.emit()
	await process_frame
	check(view.get_node("%DayLabel").text == "Day 1", "Large left day label")
	check(view.get_node("%QuotaLabel").text == "Earned: 0 gold", "Large right daily earnings")
	check(view.get_node("%DayLabel").get_theme_font_size("font_size") >= 48, "Day typography enlarged")
	check(view.get_node("%CastButton").text.contains("Bait 6 / 6"), "Bait moved to Cast")
	check(view.get_node("%ReturnButton").text.contains("Pay 180 gold"), "Rent moved to Return")
	check(view.get_node_or_null("%ForecastLabel") == null, "Forecast sentence removed entirely")
	check(not (view.get_node("%SeaPanel") as SeaReportPanel).visible, "Sea report hidden by default")
	(view.get_node("%SeaButton") as Button).mouse_entered.emit()
	check((view.get_node("%SeaPanel") as SeaReportPanel).visible, "Hover opens sea report")
	var report_style := (view.get_node("%SeaPanel") as SeaReportPanel).get_theme_stylebox("panel") as StyleBoxFlat
	check(is_equal_approx(report_style.bg_color.a, 0.20), "Sea background is eighty percent transparent")
	check((view.get_node("%SeaButton") as Button).global_position.y > view.size.y / 2, "Sea button at lower left")
	check((view.get_node("%SeaPanel") as SeaReportPanel).global_position.y < (view.get_node("%SeaButton") as Button).global_position.y, "Report appears above button")
	(view.get_node("%SeaButton") as Button).mouse_exited.emit()
	await create_timer(0.18).timeout
	check(not (view.get_node("%SeaPanel") as SeaReportPanel).visible, "Leaving the hover area dismisses report")
	(view.get_node("%CastButton") as Button).pressed.emit()
	await create_timer(0.06).timeout
	check(view.get_node("%CatchCard").visible, "Catch opens pixel card")
	check(view.get_node("%CatchChoiceDetails").text == "SARDINE", "Card uses English fish name")
	check(view.get_node("%CatchWeight").text == "3 kg", "Card weight")
	check(view.get_node("%CatchPrice").text == "30 gold", "Card sale price without bonus")
	check(view.get_node("%CatchRarity").text == "COMMON", "Card rarity translated")
	check(not view.get_node("%NewCatchLabel").visible, "Legacy species does not show a new badge")
	check(not (view.get_node("%SeaPanel") as SeaReportPanel).visible, "Sea report dismissed for card")
	(view.get_node("%ReleaseButton") as Button).pressed.emit()
	var session := controller.get_session()
	check(session.get_current_day().get_fish_count() == 0, "Card release reaches model")
	check(view.get_node("%CastButton").text.contains("Bait 5 / 6"), "Bait count updates after release")
	var catalog := session.get_catalog()
	check(catalog.get_catch_count(&"sardine") == 1 and catalog.get_best_weight_kg(&"sardine") == 3, "Released fish contributes to catalogue catch record")
	check(session.get_current_day().get_discoveries().is_empty(), "Legacy migration never pays again")
	view.open_field_guide()
	(view.get_node("%FieldGuide") as FieldGuideBook).select(&"sardine")
	check(view.get_node("%CatalogFishStats").text.contains("3000 g"), "Left page displays grams")
	check(view.get_node("%CatalogFishStats").text.contains("Total caught: 1"), "Left page displays count")
	check((view.get_node("%FieldGuide") as FieldGuideBook).get_selected_species() == &"sardine", "Left page displays selected fish art")
	(view.get_node("%FieldGuide") as FieldGuideBook).close()
	(view.get_node("%CastButton") as Button).pressed.emit()
	await create_timer(0.06).timeout
	check(view.get_node("%NewCatchLabel").visible, "New species gets discovery badge")
	check(view.get_node("%CatchChoiceDetails").text == "GOLDEN TUNA", "Second card updates species")
	(view.get_node("%KeepButton") as Button).pressed.emit()
	(view.get_node("%ReturnButton") as Button).pressed.emit()
	check(view.get_node("%QuotaLabel").text == "Earned: 870 gold", "Header reflects sale and discovery correctly")
	view.open_field_guide()
	(view.get_node("%CatalogGrid").get_child(9) as Button).pressed.emit()
	check(view.get_node("%CatalogFishName").text == "GOLDEN TUNA" and view.get_node("%CatalogFishStats").text.contains("21000 g"), "Right-page selection updates left page")
	verify_english(view)
	var reload := FishCatalogStore.new(SAVE).load_catalog()
	check(reload.get_best_weight_kg(&"sardine") == 3 and reload.get_catch_count(&"golden_tuna") == 1, "Records persist through store reload")
	var next_session := GameSession.new()
	next_session.set_catalog(reload)
	next_session.start_new_game(c)
	next_session.start_day(FixedCatchSource.new([Fish.new(&"sardine", 2)]))
	next_session.get_current_day().cast()
	check(next_session.get_current_day().get_discoveries().is_empty(), "Reloaded record never rewards twice")
	check(next_session.get_catalog().get_catch_count(&"sardine") == 2 and next_session.get_catalog().get_best_weight_kg(&"sardine") == 3, "Reloaded record increments count and keeps biggest catch")
	controller.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	print("Interface: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
