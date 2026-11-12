class_name GameView
extends Control
## The screen: HUD, net, actions, menu and result overlays. Composes the sea report, catch card
## and field guide components. Renders model snapshots and emits intent; never changes game rules.

signal start_requested
signal cast_requested
signal return_requested
signal continue_requested
signal restart_requested
signal keep_requested
signal release_requested

var _session: GameSession
var _config: GameConfig
var _scenery: FishingView
var _menu: ColorRect
var _result: ColorRect
var _cast_button: Button
var _return_button: Button
var _guide_button: Button
var _sea_button: Button
var _sea_report: SeaReportPanel
var _catch_card: CatchCard
var _field_guide: FieldGuideBook


func _ready() -> void:
	theme = UiKit.make_theme()
	_scenery = $FishingView
	_build_hud()
	_build_menu_and_result()
	_catch_card = UiKit.named(CatchCard.new(), "CatchCard", self, self)
	_catch_card.build(self)
	_catch_card.keep_requested.connect(func(): keep_requested.emit())
	_catch_card.release_requested.connect(func(): release_requested.emit())
	_field_guide = UiKit.named(FieldGuideBook.new(), "FieldGuide", self, self)
	_field_guide.build(self)
	_field_guide.closed.connect(_on_field_guide_closed)
	_cast_button.disabled = true
	_return_button.disabled = true
	resized.connect(_on_resized)


## The session supplies the catalogue shown in the field guide.
func bind_session(session: GameSession) -> void:
	_session = session


func show_menu(config: GameConfig) -> void:
	_config = config
	%StartButton.text = "Start your %d-day voyage" % config.get_total_days()
	%StartButton.disabled = false
	%MenuRules.text = "%d bait per day. A net with %d slots and a %d kg limit.\nEvery cast catches a fish. Keep it or release it.\nExactly %d kg doubles fish-sale income.\nDiscover new species for a gold reward, once per voyage.\nCover the daily rent for %d days to win." % [config.bait_per_day, config.net_slots, config.weight_cap_kg, config.weight_cap_kg, config.get_total_days()]
	_menu.show()
	_result.hide()
	_sea_report.hide()


func show_game() -> void:
	_menu.hide()
	_result.hide()


func render(session: GameSession, config: GameConfig, busy: bool) -> void:
	var day := session.get_current_day()
	if day == null:
		return
	_session = session
	_config = config
	var earned := session.preview_income()
	%DayLabel.text = "Day %d / %d" % [session.get_day_number(), session.get_total_days()]
	%QuotaLabel.text = "Earned: %d gold" % earned
	_cast_button.text = "Cast · Bait %d / %d" % [day.get_bait_remaining(), config.bait_per_day]
	_return_button.text = "Return · Pay %d gold" % day.get_quota()
	%WeightLabel.text = "Net weight  %d / %d kg" % [day.get_total_weight_kg(), config.weight_cap_kg]
	if earned >= day.get_quota() and day.get_total_weight_kg() <= config.weight_cap_kg:
		%WeightLabel.text += "  ·  rent covered"
	%WeightBar.max_value = config.weight_cap_kg
	%WeightBar.value = day.get_total_weight_kg()
	%NetCount.text = "%d / %d fish" % [day.get_fish_count(), config.net_slots]
	_render_slots(day, session, config)
	var choosing := day.get_pending_fish() != null
	var active := session.get_state() == GameSession.State.DAY_ACTIVE and not busy
	_cast_button.disabled = not active or not day.can_cast()
	_return_button.disabled = not active or choosing
	_guide_button.disabled = busy or choosing
	_sea_button.disabled = busy or choosing
	_scenery.set_casting(busy)
	_sea_report.render(day, config)
	if busy or choosing or not active:
		_sea_report.hide()


func set_message(message: String) -> void:
	%CatchMessage.text = message


func describe_catch(result: CastResult, config: GameConfig) -> void:
	match result.get_status():
		CastResult.Status.CAUGHT:
			set_message("Caught %s. Keep or release?" % _fish_name(result.get_fish().get_species_id(), config))
		CastResult.Status.EMPTY:
			set_message("Nothing bit. One bait used.")
		CastResult.Status.SOURCE_ERROR:
			set_message("Could not read catch data. No bait spent; please try again.")


func show_catch_choice(session: GameSession, config: GameConfig) -> void:
	var day := session.get_current_day()
	var fish := day.get_pending_fish()
	if fish == null:
		return
	var definition := _definition(fish.get_species_id(), config)
	var overweight := day.get_total_weight_kg() + fish.get_weight_kg() > config.weight_cap_kg
	_sea_report.hide()
	_sea_report.blocked = true
	_catch_card.present(
		fish,
		_fish_name(fish.get_species_id(), config),
		"Common" if definition == null else definition.rarity,
		session.get_fish_value(fish),
		day.was_last_catch_discovered(),
		overweight,
	)


func hide_catch_choice() -> void:
	_catch_card.close()
	_sea_report.blocked = false
	_cast_button.grab_focus()


func open_field_guide() -> void:
	if _config == null:
		return
	_sea_report.hide()
	_sea_report.blocked = true
	_field_guide.open(_config.fish_definitions, FishCatalog.new() if _session == null else _session.get_catalog())


func show_result(result: DayResult, session: GameSession) -> void:
	var title := "Today's rent is covered"
	if session.get_state() == GameSession.State.VICTORY:
		title = "Safe return · Victory"
	elif not result.is_passed():
		title = "Voyage over · Rent unpaid"
	%ResultTitle.text = title
	var reasons := {
		FishingDay.EndReason.RETURNED: "Returned to shore",
		FishingDay.EndReason.BUST: "Net broken. Today's fish-sale income is lost.",
		FishingDay.EndReason.NET_FULL: "Net full. Returned automatically.",
		FishingDay.EndReason.BAIT_EMPTY: "Out of bait. Returned automatically.",
	}
	%ResultReason.text = reasons.get(result.get_end_reason(), "Day ended")
	if result.is_perfect():
		%ResultReason.text += " · Perfect catch bonus"
	%ResultDetails.text = "Day %d  ·  %d fish  ·  %d kg\n\nDaily income    %d gold\nDaily rent    %d gold\nSaved today    %d gold\nTotal savings    %d gold\n\nDiscovery reward    %d gold (included, never doubled)" % [result.get_day_number(), result.get_fish_count(), result.get_total_weight_kg(), result.get_income(), result.get_quota(), result.get_coin_gain(), session.get_coins(), result.get_discovery_income()]
	if not result.is_passed():
		%ResultDetails.text += "\nIncome is below rent. Savings cannot cover the gap."
	%ContinueButton.visible = session.can_advance_day()
	%RestartButton.text = "Start a new voyage"
	_result.show()
	_sea_report.hide()
	if session.can_advance_day():
		%ContinueButton.grab_focus()
	else:
		%RestartButton.grab_focus()


func show_error(message: String) -> void:
	_result.hide()
	_cast_button.disabled = true
	_return_button.disabled = true
	_scenery.set_casting(false)
	%MenuRules.text = message
	%StartButton.disabled = true
	_menu.show()


func _build_hud() -> void:
	var margin: MarginContainer = UiKit.named(MarginContainer.new(), "Margin", self, self)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.offset_left = 38
	margin.offset_right = -38
	margin.offset_top = 28
	margin.offset_bottom = -28
	var layout := UiKit.column(margin, 16)
	var header_row := UiKit.row(UiKit.panel(layout, Color(0.08, 0.19, 0.24, 0.88), 14, 20))
	UiKit.named(UiKit.label("Day 1", 52), "DayLabel", header_row, self)
	UiKit.space(header_row, false)
	UiKit.named(UiKit.label("Earned: 0 gold", 48), "QuotaLabel", header_row, self)
	UiKit.space(layout)
	var tools := UiKit.row(layout)
	_sea_button = UiKit.named(UiKit.button("Today's Sea"), "SeaButton", tools, self)
	_sea_button.custom_minimum_size = Vector2(240, 54)
	UiKit.space(tools, false)
	var message: Label = UiKit.named(UiKit.label("", 18, Color("aec8c6")), "CatchMessage", tools, self)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	message.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var net_layout := UiKit.column(UiKit.panel(layout, Color(0.08, 0.19, 0.24, 0.94), 14, 22), 12)
	var net_header := UiKit.row(net_layout)
	UiKit.named(UiKit.label("Net weight  0 / 21 kg", 23), "WeightLabel", net_header, self)
	UiKit.space(net_header, false)
	UiKit.named(UiKit.label("0 / 5 fish", 23), "NetCount", net_header, self)
	var progress: ProgressBar = UiKit.named(ProgressBar.new(), "WeightBar", net_layout, self)
	progress.custom_minimum_size.y = 12
	progress.show_percentage = false
	var slots: HBoxContainer = UiKit.named(HBoxContainer.new(), "FishSlots", net_layout, self)
	slots.add_theme_constant_override("separation", 12)
	slots.custom_minimum_size.y = 72
	var actions := UiKit.row(layout, 18)
	_cast_button = UiKit.named(UiKit.button("Cast · Bait 6 / 6"), "CastButton", actions, self)
	_return_button = UiKit.named(UiKit.button("Return · Pay 180 gold"), "ReturnButton", actions, self)
	_guide_button = UiKit.named(UiKit.button("Field Guide"), "CatalogButton", actions, self)
	for item in [_cast_button, _return_button]:
		item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item.custom_minimum_size.y = 64
	_guide_button.custom_minimum_size = Vector2(190, 64)
	_cast_button.pressed.connect(func(): cast_requested.emit())
	_return_button.pressed.connect(func(): return_requested.emit())
	_guide_button.pressed.connect(open_field_guide)
	_sea_report = UiKit.named(SeaReportPanel.new(), "SeaPanel", self, self)
	_sea_report.build(_sea_button, self)


func _build_menu_and_result() -> void:
	_menu = _overlay("MenuOverlay", 0.84)
	var menu_panel := UiKit.panel(UiKit.centered(_menu), UiKit.DARK, 16, 36)
	menu_panel.custom_minimum_size.x = 760
	var menu_layout := UiKit.column(menu_panel, 22)
	menu_layout.add_child(_centered_label("FISHING 21  /  A SEVEN-DAY VOYAGE", 18, Color("9ec9c6")))
	menu_layout.add_child(_centered_label("Every catch is a choice.", 48))
	UiKit.named(_centered_label("", 23), "MenuRules", menu_layout, self)
	UiKit.named(UiKit.button("Start your voyage"), "StartButton", menu_layout, self).pressed.connect(func(): start_requested.emit())
	menu_layout.add_child(_centered_label("F11: toggle fullscreen  ·  Esc: leave fullscreen", 16, Color("9cbdbd")))
	_result = _overlay("ResultOverlay", 0.84)
	var result_panel := UiKit.panel(UiKit.centered(_result), UiKit.DARK, 16, 32)
	result_panel.custom_minimum_size.x = 740
	var result_layout := UiKit.column(result_panel, 16)
	for key in ["ResultTitle", "ResultReason", "ResultDetails"]:
		UiKit.named(_centered_label("", 34 if key == "ResultTitle" else 22), key, result_layout, self)
	UiKit.named(UiKit.button("Continue · Next day"), "ContinueButton", result_layout, self).pressed.connect(func(): continue_requested.emit())
	UiKit.named(UiKit.button("Restart"), "RestartButton", result_layout, self).pressed.connect(func(): restart_requested.emit())
	UiKit.named(UiKit.button("Field Guide"), "ResultCatalogButton", result_layout, self).pressed.connect(open_field_guide)


func _render_slots(day: FishingDay, session: GameSession, config: GameConfig) -> void:
	var slots: HBoxContainer = %FishSlots
	for child in slots.get_children():
		slots.remove_child(child)
		child.queue_free()
	var catches := day.get_fish()
	for index in range(config.net_slots):
		var text := UiKit.label("— Empty —", 20, Color("a9c1bf"))
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if index < catches.size():
			var fish := catches[index]
			text.text = "%s\n%d kg · %d gold" % [_fish_name(fish.get_species_id(), config), fish.get_weight_kg(), session.get_fish_value(fish)]
		slots.add_child(text)


func _on_field_guide_closed() -> void:
	_sea_report.blocked = _catch_card.visible
	if _menu.visible:
		%StartButton.grab_focus()
	elif _result.visible:
		%ResultCatalogButton.grab_focus()
	else:
		_guide_button.grab_focus()


func _overlay(node_name: String, opacity: float) -> ColorRect:
	var overlay: ColorRect = UiKit.named(ColorRect.new(), node_name, self, self)
	UiKit.dim(overlay, opacity)
	return overlay


func _centered_label(text: String, font_size: int, color: Color = UiKit.INK) -> Label:
	var item := UiKit.label(text, font_size, color)
	item.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return item


func _definition(species_id: StringName, config: GameConfig) -> FishDefinition:
	for definition in config.fish_definitions:
		if definition.species_id == species_id:
			return definition
	return null


func _fish_name(species_id: StringName, config: GameConfig) -> String:
	var definition := _definition(species_id, config)
	return String(species_id).replace("_", " ").capitalize() if definition == null else definition.display_name


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_F11:
		var window := get_window()
		window.mode = Window.MODE_WINDOWED if window.mode == Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_ESCAPE:
		if _field_guide.visible:
			_field_guide.close()
		elif get_window().mode == Window.MODE_FULLSCREEN:
			get_window().mode = Window.MODE_WINDOWED
		get_viewport().set_input_as_handled()


func _on_resized() -> void:
	if _sea_report.visible:
		_sea_report.reveal()
