class_name GameView
extends Control
## Renders model snapshots and emits intent. Never mutates game rules.

signal start_requested
signal cast_requested
signal return_requested
signal continue_requested
signal restart_requested

@onready var _menu: Control = %MenuOverlay
@onready var _result: Control = %ResultOverlay
@onready var _cast_button: Button = %CastButton
@onready var _return_button: Button = %ReturnButton
@onready var _scenery: FishingView = $FishingView
@onready var _sea_report: SeaReportPanel = %SeaPanel


func _ready() -> void:
	_apply_theme()
	%StartButton.pressed.connect(func(): start_requested.emit())
	_cast_button.pressed.connect(func(): cast_requested.emit())
	_return_button.pressed.connect(func(): return_requested.emit())
	%ContinueButton.pressed.connect(func(): continue_requested.emit())
	%RestartButton.pressed.connect(func(): restart_requested.emit())
	_result.hide()
	_cast_button.disabled = true
	_return_button.disabled = true


func show_menu(config: GameConfig) -> void:
	%StartButton.text = "Start your %d-day voyage" % config.get_total_days()
	%StartButton.disabled = false
	%MenuRules.text = "%d bait per day. Your net holds up to %d fish.\nOver %d kg breaks the net. Exactly %d kg pays ×%d.\nCover the daily rent for %d days to win.\nKeep every catch. Choose when to return to shore." % [config.bait_per_day, config.net_slots, config.weight_cap_kg, config.weight_cap_kg, config.perfect_multiplier, config.get_total_days()]
	if config.sea_pool_size > 0:
		%MenuRules.text += "\nEach morning the sea report shows today's %d catches.\nEvery cast takes one out — count what is left." % config.sea_pool_size
	_menu.show()
	_result.hide()


func show_game() -> void:
	_menu.hide()
	_result.hide()


func render(session: GameSession, config: GameConfig, busy: bool) -> void:
	var day := session.get_current_day()
	if day == null:
		return
	%DayLabel.text = "Day %d / %d" % [session.get_day_number(), session.get_total_days()]
	var rent_kg := _rent_weight_kg(day.get_quota(), config)
	%QuotaLabel.text = "Daily rent  %d gold  (≥ %d kg)" % [day.get_quota(), rent_kg]
	%CoinsLabel.text = "Savings  %d gold" % session.get_coins()
	%BaitLabel.text = "Bait  %d / %d" % [day.get_bait_remaining(), config.bait_per_day]
	%WeightLabel.text = "Net weight  %d / %d kg" % [day.get_total_weight_kg(), config.weight_cap_kg]
	if day.get_total_weight_kg() >= rent_kg and day.get_total_weight_kg() <= config.weight_cap_kg:
		%WeightLabel.text += "  ·  rent covered"
	%WeightBar.max_value = config.weight_cap_kg
	%WeightBar.value = day.get_total_weight_kg()
	%NetCount.text = "%d / %d fish" % [day.get_fish_count(), config.net_slots]
	var catches := day.get_fish()
	var slots: HBoxContainer = %FishSlots
	for child in slots.get_children():
		slots.remove_child(child)
		child.queue_free()
	for index in range(config.net_slots):
		var slot := Label.new()
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot.text = "— Empty —"
		if index < catches.size():
			var fish := catches[index]
			slot.text = "%s · %d kg" % [_fish_name(fish.get_species_id(), config), fish.get_weight_kg()]
		slots.add_child(slot)
	var active := session.get_state() == GameSession.State.DAY_ACTIVE and not busy
	_cast_button.disabled = not active or not day.can_cast()
	_return_button.disabled = not active
	_scenery.set_casting(busy)
	var forecast: CatchForecast = null if busy else session.get_next_cast_forecast()
	_sea_report.render(day, config, forecast)
	_tint_weight_bar(forecast)


func _tint_weight_bar(forecast: CatchForecast) -> void:
	var fill := StyleBoxFlat.new()
	fill.set_corner_radius_all(5)
	fill.bg_color = SeaReportPanel.risk_color(forecast)
	%WeightBar.add_theme_stylebox_override("fill", fill)


func _rent_weight_kg(quota: int, config: GameConfig) -> int:
	return ceili(float(quota) / config.price_per_kg)


func set_message(message: String) -> void:
	%CatchMessage.text = message


func describe_catch(result: CastResult, config: GameConfig) -> void:
	if result.get_status() == CastResult.Status.EMPTY:
		set_message("No catch this time. One bait used. Try again?")
	elif result.get_status() == CastResult.Status.CAUGHT:
		var fish := result.get_fish()
		set_message("Caught a %s, %d kg! Added to your net." % [_fish_name(fish.get_species_id(), config), fish.get_weight_kg()])
	elif result.get_status() == CastResult.Status.SOURCE_ERROR:
		set_message("Invalid catch data. No bait used. Please try again.")


func show_result(result: DayResult, session: GameSession) -> void:
	var title := "Today's rent is covered"
	if session.get_state() == GameSession.State.VICTORY:
		title = "Safe return · Victory"
	elif not result.is_passed():
		title = "Voyage over · Rent unpaid"
	%ResultTitle.text = title
	var reasons := {
		FishingDay.EndReason.RETURNED: "Returned to shore",
		FishingDay.EndReason.BUST: "Net broken. Today's catch is lost.",
		FishingDay.EndReason.NET_FULL: "Net full. Returned automatically.",
		FishingDay.EndReason.BAIT_EMPTY: "Out of bait. Returned automatically.",
	}
	%ResultReason.text = reasons.get(result.get_end_reason(), "Day ended")
	if result.is_perfect():
		%ResultReason.text += " · Perfect catch bonus"
	%ResultDetails.text = "Day %d  ·  %d fish  ·  %d kg\n\nDaily income    %d gold\nDaily rent    %d gold\nNet income    %+d gold\nSaved today    %d gold\n\nTotal savings    %d gold" % [result.get_day_number(), result.get_fish_count(), result.get_total_weight_kg(), result.get_income(), result.get_quota(), result.get_net_income(), result.get_coin_gain(), session.get_coins()]
	if not result.is_passed():
		%ResultDetails.text += "\n\nIncome is below rent. Savings cannot cover the gap."
	%ContinueButton.visible = session.can_advance_day()
	%RestartButton.text = "Restart" if not session.can_advance_day() else "Start a new voyage"
	_result.show()
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


func _fish_name(species_id: StringName, config: GameConfig) -> String:
	for definition in config.fish_definitions:
		if definition.species_id == species_id:
			return definition.display_name
	return String(species_id)


func _apply_theme() -> void:
	var ui_theme := Theme.new()
	ui_theme.default_font_size = 20
	ui_theme.set_color("font_color", "Label", Color("e7eee4"))
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("16313f")
	panel.set_corner_radius_all(14)
	panel.content_margin_left = 24
	panel.content_margin_right = 24
	panel.content_margin_top = 18
	panel.content_margin_bottom = 18
	ui_theme.set_stylebox("panel", "PanelContainer", panel)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var button := StyleBoxFlat.new()
		button.set_corner_radius_all(10)
		button.bg_color = Color("25646b")
		if state == "hover" or state == "focus":
			button.bg_color = Color("387d7c")
		elif state == "pressed":
			button.bg_color = Color("194b55")
		elif state == "disabled":
			button.bg_color = Color("263e48")
		button.content_margin_top = 15
		button.content_margin_bottom = 15
		button.content_margin_left = 24
		button.content_margin_right = 24
		ui_theme.set_stylebox(state, "Button", button)
	ui_theme.set_color("font_color", "Button", Color("fff2d5"))
	ui_theme.set_color("font_disabled_color", "Button", Color("71858a"))
	var bar := StyleBoxFlat.new()
	bar.bg_color = Color("0d2531")
	bar.set_corner_radius_all(5)
	ui_theme.set_stylebox("background", "ProgressBar", bar)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("d9aa6b")
	fill.set_corner_radius_all(5)
	ui_theme.set_stylebox("fill", "ProgressBar", fill)
	theme = ui_theme
