extends SceneTree
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
	var controller := load("res://scenes/main.tscn").instantiate() as GameController
	controller.cast_delay_seconds = 0.01
	controller.catch_source_factory = func() -> CatchSource: return FixedCatchSource.new([Fish.new(&"sardine", 3), Fish.new(&"golden_tuna", 21)])
	root.add_child(controller)
	await process_frame
	var view := controller.get_node("GameView") as GameView
	var guide := view.get_node("%FieldGuide") as FieldGuideBook
	check(view.get_node("%MenuOverlay").visible, "Menu opens")
	view.open_field_guide()
	check(view.get_node("%CatalogDetails").text.contains("Collected 0 / 10"), "Field guide starts empty")
	check(view.get_node("%CatalogGrid").get_child_count() == 10, "Collection has ten cells")
	check((view.get_node("%CatalogGrid").get_child(0) as Button).disabled, "Uncollected silhouette cannot reveal details")
	check(view.get_node("%CatalogFishName").text == "UNEXPLORED WATERS", "Empty guide shows placeholder page")
	guide.close()
	(view.get_node("%StartButton") as Button).pressed.emit()
	await process_frame
	check(view.get_node("%DayLabel").text == "Day 1 / 7", "Day label shows current and total days")
	check(view.get_node("%QuotaLabel").text == "0 gold", "Large right daily earnings")
	check((view.get_node("%EarningsCoin") as TextureRect).texture != null, "Income has a coin icon")
	var return_button := view.get_node("%ReturnButton") as Button
	check((return_button.get_theme_stylebox("normal") as StyleBoxFlat).bg_color == GameView.RETURN_GREY, "Return is grey below rent")
	check(not return_button.disabled, "Grey return remains usable below rent")
	var cast_color := (view.get_node("%CastButton").get_theme_stylebox("normal") as StyleBoxFlat).bg_color
	var guide_color := (view.get_node("%CatalogButton").get_theme_stylebox("normal") as StyleBoxFlat).bg_color
	check(cast_color != guide_color and cast_color != GameView.RETURN_GREY and guide_color != GameView.RETURN_GREY, "Three action buttons have distinct colours")
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
	check(view.get_node("%NewCatchLabel").visible, "First species of the voyage shows the discovery badge")
	check(not (view.get_node("%SeaPanel") as SeaReportPanel).visible, "Sea report dismissed for card")
	(view.get_node("%ReleaseButton") as Button).pressed.emit()
	var session := controller.get_session()
	check(session.get_current_day().get_fish_count() == 0, "Card release reaches model")
	check(view.get_node("%CastButton").text.contains("Bait 5 / 6"), "Bait count updates after release")
	var catalog := session.get_catalog()
	check(catalog.get_catch_count(&"sardine") == 1 and catalog.get_best_weight_kg(&"sardine") == 3, "Released fish contributes to catalogue catch record")
	check(session.get_current_day().get_discoveries().size() == 1 and view.get_node("%QuotaLabel").text == "3 gold", "Released discovery still pays its reward")
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
	check(view.get_node("%QuotaLabel").text == "873 gold", "Header: 840 doubled sale + 30 + 3 discovery")
	view.open_field_guide()
	(view.get_node("%CatalogGrid").get_child(9) as Button).pressed.emit()
	check(view.get_node("%CatalogFishName").text == "GOLDEN TUNA" and view.get_node("%CatalogFishStats").text.contains("21000 g"), "Right-page selection updates left page")
	verify_english(view)
	guide.close()
	(view.get_node("%ContinueButton") as Button).pressed.emit()
	await process_frame
	check(view.get_node("%DayLabel").text == "Day 2 / 7", "Day label advances with the voyage")
	(view.get_node("%CastButton") as Button).pressed.emit()
	await create_timer(0.06).timeout
	check(not view.get_node("%NewCatchLabel").visible, "Same voyage: sardine is no longer new")
	(view.get_node("%KeepButton") as Button).pressed.emit()
	(view.get_node("%ReturnButton") as Button).pressed.emit()
	check(session.get_state() == GameSession.State.GAME_OVER, "30 gold misses the Day 2 rent")
	(view.get_node("%RestartButton") as Button).pressed.emit()
	await process_frame
	check(view.get_node("%DayLabel").text == "Day 1 / 7", "New voyage returns to Day 1 of 7")
	check(session.get_catalog().get_discovered_count() == 0, "New voyage resets the field guide")
	view.open_field_guide()
	check(view.get_node("%CatalogDetails").text.contains("Collected 0 / 10"), "Field guide view is empty again")
	guide.close()
	(view.get_node("%CastButton") as Button).pressed.emit()
	await create_timer(0.06).timeout
	check(view.get_node("%NewCatchLabel").visible, "Discovery reward is available again in a new voyage")
	controller.queue_free()
	await process_frame
	print("Interface: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
