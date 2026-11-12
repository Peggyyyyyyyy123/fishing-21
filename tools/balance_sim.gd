extends SceneTree
## Dev helper: compares stop strategies under independent draws vs the finite daily sea.
## Forced-keep baseline (every catch kept); income is weight-based, not the Stage 3 species economy.
## Usage: --headless --script res://tools/balance_sim.gd -- [days] [pool sizes, e.g. 0,8,12]
## Income is reported in kg-equivalent (gold / price_per_kg), as in the config workbook.


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var days := int(args[0]) if not args.is_empty() else 50000
	var base := load("res://config/default_game_config.tres") as GameConfig
	var strategies := {
		"Always cast": func(_w: int, _f: CatchForecast) -> bool: return true,
		"Weight < 14 kg": func(w: int, _f: CatchForecast) -> bool: return w < 14,
		"Break chance < 20%": func(_w: int, f: CatchForecast) -> bool: return f.get_bust_chance() < 0.2,
		"Break chance < 25%": func(_w: int, f: CatchForecast) -> bool: return f.get_bust_chance() < 0.25,
	}
	print("days per row: %d" % days)
	print("%-8s %-20s %8s %8s %8s %8s %8s %8s" % ["sea", "strategy", "mean kg", "bust", "perfect", "≥4kg", "≥10kg", "≥14kg"])
	var pool_sizes := [0, base.sea_pool_size]
	if args.size() > 1:
		pool_sizes = Array(args[1].split(",")).map(func(s: String) -> int: return int(s))
	for pool_size in pool_sizes:
		var config := base.duplicate(true) as GameConfig
		config.sea_pool_size = pool_size
		var rng := RandomNumberGenerator.new()
		rng.seed = 2026
		for name in strategies:
			_simulate(config, rng, days, name, strategies[name])
	quit(0)


func _simulate(config: GameConfig, rng: RandomNumberGenerator, days: int, label: String, keep_casting: Callable) -> void:
	var income_sum := 0.0
	var busts := 0
	var perfects := 0
	var reach := {4: 0, 10: 0, 14: 0}
	for index in range(days):
		var source: CatchSource = SeaPoolCatchSource.new(config, rng) if config.sea_pool_size > 0 else RandomCatchSource.new(config, rng)
		var day := FishingDay.new(1, 0, config.bait_per_day, config.net_slots, config.weight_cap_kg, source)
		while day.can_cast():
			var forecast := CatchForecast.calculate(config.fish_definitions, day.get_next_cast_chances(), day.get_total_weight_kg(), config.weight_cap_kg)
			if not keep_casting.call(day.get_total_weight_kg(), forecast):
				break
			if day.cast().get_status() == CastResult.Status.CAUGHT:
				day.resolve_catch(true)  # Forced-keep baseline, as in Stage 1.
		if not day.is_finished():
			day.return_to_shore()
		var weight := day.get_total_weight_kg()
		var income := 0.0
		if day.get_end_reason() == FishingDay.EndReason.BUST:
			busts += 1
		else:
			income = weight * (config.perfect_multiplier if weight == config.weight_cap_kg else 1)
			if weight == config.weight_cap_kg:
				perfects += 1
		income_sum += income
		for target in reach:
			if income >= target:
				reach[target] += 1
	var mode := "pool %d" % config.sea_pool_size if config.sea_pool_size > 0 else "random"
	print("%-8s %-20s %8.2f %7.1f%% %7.1f%% %7.1f%% %7.1f%% %7.1f%%" % [mode, label, income_sum / days, 100.0 * busts / days, 100.0 * perfects / days, 100.0 * reach[4] / days, 100.0 * reach[10] / days, 100.0 * reach[14] / days])
