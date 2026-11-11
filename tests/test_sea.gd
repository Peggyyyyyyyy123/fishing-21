extends SceneTree
## Finite daily sea, next-cast odds and the sea report UI.

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var config := LegacyTestConfig.make()
	_test_config(config)
	_test_pool(config)
	_test_forecast(config)
	_test_session(config)
	await _test_ui()
	print("Sea: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _test_config(config: GameConfig) -> void:
	_check(config.sea_pool_size == 12, "Default sea holds 12 outcomes")
	var invalid := config.duplicate(true) as GameConfig
	invalid.sea_pool_size = config.bait_per_day - 1
	_check(not invalid.validate().is_empty(), "Sea smaller than daily bait rejected")
	invalid.sea_pool_size = -1
	_check(not invalid.validate().is_empty(), "Negative sea size rejected")
	invalid.sea_pool_size = 0
	_check(invalid.validate().is_empty(), "Zero sea size selects independent draws")


func _test_pool(config: GameConfig) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	var source := SeaPoolCatchSource.new(config, rng)
	_check(source.get_remaining_total() == 12, "Random stocking fills the configured size")
	var stocked := {&"nothing": 1, &"small": 2, &"big": 1}
	source = SeaPoolCatchSource.new(config, rng, stocked)
	_check(source.get_remaining_total() == 4, "Scripted stock is used as given")
	var seen := {}
	for index in range(4):
		var fish := source.draw()
		var id: StringName = &"nothing" if fish == null else fish.get_species_id()
		seen[id] = seen.get(id, 0) + 1
		if fish != null:
			var definition := _definition(config, id)
			_check(fish.get_weight_kg() >= definition.min_weight_kg and fish.get_weight_kg() <= definition.max_weight_kg, "Pool weight inside species range")
	_check(seen.get(&"nothing", 0) == 1 and seen.get(&"small", 0) == 2 and seen.get(&"big", 0) == 1, "Draws empty the pool without replacement")
	_check(source.get_remaining_total() == 0 and source.get_next_draw_chances().is_empty(), "Drained sea has no odds")
	_check(source.draw() == null, "Drained sea yields no catch")
	_check(source.get_initial_counts()[&"small"] == 2, "Initial counts stay for the report")
	source = SeaPoolCatchSource.new(config, rng, {&"small": 3, &"huge": 1})
	var chances := source.get_next_draw_chances()
	_check(is_equal_approx(chances[&"small"], 0.75) and is_equal_approx(chances[&"huge"], 0.25), "Odds follow remaining counts")
	# Over many stocked days the marginal outcome rate matches the configured distribution.
	var totals := {}
	for day in range(2000):
		var counts := SeaPoolCatchSource.new(config, rng).get_initial_counts()
		for id in counts:
			totals[id] = totals.get(id, 0) + counts[id]
	for definition in config.fish_definitions:
		_check(absf(float(totals[definition.species_id]) / 24000.0 - definition.probability) < 0.02, "Stocking frequency matches %s" % definition.species_id)


func _test_forecast(config: GameConfig) -> void:
	var odds := RandomCatchSource.new(config).get_next_draw_chances()
	var forecast := CatchForecast.calculate(config.fish_definitions, odds, 14, 21)
	_check(is_equal_approx(forecast.get_bust_chance(), 0.175), "Independent odds at 14 kg break 17.5%")
	_check(is_equal_approx(forecast.get_perfect_chance(), 0.025), "Independent odds at 14 kg hit 21 kg 2.5%")
	_check(is_equal_approx(forecast.get_empty_chance(), 0.2), "Empty chance reported")
	_check(forecast.get_room_kg() == 7, "Room left reported")
	forecast = CatchForecast.calculate(config.fish_definitions, odds, 0, 21)
	_check(is_zero_approx(forecast.get_bust_chance()), "Empty net cannot break")
	forecast = CatchForecast.calculate(config.fish_definitions, odds, 21, 21)
	_check(is_equal_approx(forecast.get_bust_chance(), 0.8), "At 21 kg every fish breaks the net")
	_check(is_zero_approx(forecast.get_perfect_chance()), "No perfect chance with zero room")
	var pool := {&"nothing": 0.5, &"small": 0.5}
	forecast = CatchForecast.calculate(config.fish_definitions, pool, 19, 21)
	_check(is_equal_approx(forecast.get_bust_chance(), 0.25), "Small-only sea at 19 kg breaks on 3 or 4 kg")
	_check(is_equal_approx(forecast.get_perfect_chance(), 0.125), "Small-only sea at 19 kg perfect on 2 kg")
	_check(CatchForecast.calculate(config.fish_definitions, {}, 5, 21) == null, "Unknown odds give no forecast")


func _test_session(config: GameConfig) -> void:
	var session := GameSession.new()
	session.start_new_game(config)
	session.start_day()
	var day := session.get_current_day()
	_check(not day.get_sea_remaining_counts().is_empty(), "Default day uses a finite sea")
	var before := _sum(day.get_sea_remaining_counts())
	var result := day.cast()
	if result.get_status() == CastResult.Status.CAUGHT:
		day.resolve_catch(false)
	_check(_sum(day.get_sea_remaining_counts()) == before - 1, "Each cast removes one outcome, kept or released")
	var legacy := config.duplicate(true) as GameConfig
	legacy.sea_pool_size = 0
	session = GameSession.new()
	session.start_new_game(legacy)
	session.start_day()
	_check(session.get_current_day().get_sea_remaining_counts().is_empty(), "Zero sea size keeps independent draws")
	_check(not session.get_current_day().get_next_cast_chances().is_empty(), "Independent draws still report odds")


func _test_ui() -> void:
	var save := "res://tests/.sea_catalog.cfg"
	var controller := load("res://scenes/main.tscn").instantiate() as GameController
	controller.cast_delay_seconds = 0.001
	controller.game_config = LegacyTestConfig.make()
	controller.catalog_store = FishCatalogStore.new(save)
	var config := controller.game_config
	controller.catch_source_factory = func() -> CatchSource:
		return SeaPoolCatchSource.new(config, null, {&"small": 5, &"huge": 1})
	root.add_child(controller)
	await process_frame
	var view := controller.get_node("GameView") as GameView
	var report := view.get_node("%SeaPanel") as SeaReportPanel
	_check(view.get_node("%MenuRules").text.contains("sea report"), "Menu explains the sea report")
	(view.get_node("%StartButton") as Button).pressed.emit()
	_check(view.get_node("%ReturnButton").text.contains("Pay 40 gold"), "Rent shown on Return")
	_check(view.get_node("%SeaTitle").text.contains("6 fish left"), "Sea title shows remaining outcomes")
	var grid := view.get_node("%SeaGrid") as GridContainer
	_check(grid.get_child_count() == config.fish_definitions.size() * 3, "One report row per outcome")
	_check(_grid_has(grid, "5 / 5") and _grid_has(grid, "17–21 kg"), "Report shows counts and weight ranges")
	_check(view.get_node_or_null("%ForecastLabel") == null, "Next-cast sentence removed in Stage 3")
	(view.get_node("%CastButton") as Button).pressed.emit()
	_check(not report.visible, "Sea report hidden while casting")
	await create_timer(0.03).timeout
	_check(view.get_node("%SeaTitle").text.contains("5 fish left"), "Report updates after a cast")
	controller.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save))


func _grid_has(grid: GridContainer, text: String) -> bool:
	for child in grid.get_children():
		if (child as Label).text == text:
			return true
	return false


func _definition(config: GameConfig, id: StringName) -> FishDefinition:
	for definition in config.fish_definitions:
		if definition.species_id == id:
			return definition
	return null


func _sum(counts: Dictionary) -> int:
	var total := 0
	for id in counts:
		total += counts[id]
	return total


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(label)
