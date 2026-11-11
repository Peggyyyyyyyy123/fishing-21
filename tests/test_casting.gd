extends SceneTree

class ReentrantCatchSource:
	extends CatchSource

	var day: FishingDay
	var nested_status: CastResult.Status

	func draw() -> Fish:
		nested_status = day.cast().get_status()
		return Fish.new(&"small", 2)


var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	_test_cast_rules()
	_test_random_source()
	_test_session()
	print("Casting: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _test_cast_rules() -> void:
	var source := FixedCatchSource.new([null, Fish.new(&"small", 3)])
	var day := FishingDay.new(1, 40, 6, 5, 21, source)
	_check(day.can_cast(), "Fresh day permits casting")
	var result := KeepEveryCatch.cast(day)
	_check(result.get_status() == CastResult.Status.EMPTY and result.was_accepted(), "Empty catch is a valid cast")
	_check(day.get_bait_remaining() == 5 and day.get_fish_count() == 0, "Empty catch consumes bait but no slot")
	_check(day.get_total_weight_kg() == 0 and not day.is_finished(), "Empty catch preserves weight and active day")
	result = KeepEveryCatch.cast(day)
	_check(result.get_status() == CastResult.Status.CAUGHT, "Fish catch is reported")
	_check(day.get_fish_count() == 1 and day.get_total_weight_kg() == 3 and day.get_bait_remaining() == 4, "Fish is forcibly kept")
	result.get_fish()._weight_kg = 100
	_check(day.get_total_weight_kg() == 3 and result.get_fish().get_weight_kg() == 3, "Result snapshots cannot mutate catch")
	source = FixedCatchSource.new([Fish.new(&"mid", 10), Fish.new(&"big", 11), null, Fish.new(&"small", 1)])
	day = FishingDay.new(1, 40, 6, 5, 21, source)
	KeepEveryCatch.cast(day)
	KeepEveryCatch.cast(day)
	_check(day.get_total_weight_kg() == 21 and day.can_cast(), "21 kg does not automatically end day")
	KeepEveryCatch.cast(day)
	_check(day.get_total_weight_kg() == 21 and day.can_cast(), "Empty catch at 21 kg keeps day active")
	KeepEveryCatch.cast(day)
	_check(day.is_finished() and day.get_end_reason() == FishingDay.EndReason.BUST, "Next fish can cause bust")
	var bait_before := day.get_bait_remaining()
	_check(not KeepEveryCatch.cast(day).was_accepted() and source.get_draw_count() == 4, "Casting after bust does not draw")
	_check(day.get_bait_remaining() == bait_before and day.get_fish_count() == 3, "Rejected cast preserves state")
	source = FixedCatchSource.new([null, null, null, null, null, null])
	day = FishingDay.new(1, 40, 6, 5, 21, source)
	for index in range(6):
		KeepEveryCatch.cast(day)
	_check(day.get_bait_remaining() == 0 and day.get_fish_count() == 0, "Six empty catches exhaust bait")
	_check(day.get_end_reason() == FishingDay.EndReason.BAIT_EMPTY and not day.can_cast(), "Bait exhaustion ends day")
	_check(KeepEveryCatch.cast(day).get_status() == CastResult.Status.REJECTED and source.get_draw_count() == 6, "Seventh cast rejected")
	source = FixedCatchSource.new([Fish.new(&"test", 4), Fish.new(&"test", 4), Fish.new(&"test", 4), Fish.new(&"test", 4), Fish.new(&"test", 6)])
	day = FishingDay.new(1, 40, 5, 5, 21, source)
	for index in range(5):
		KeepEveryCatch.cast(day)
	_check(day.get_end_reason() == FishingDay.EndReason.BUST, "Bust beats full net and empty bait together")
	_check(day.get_total_weight_kg() == 22 and day.get_fish_count() == 5, "Bust-causing fish is kept")
	source = FixedCatchSource.new([Fish.new(&"test", 5), Fish.new(&"test", 5), Fish.new(&"test", 5), Fish.new(&"test", 5), Fish.new(&"test", 1)])
	day = FishingDay.new(1, 40, 6, 5, 21, source)
	for index in range(5):
		KeepEveryCatch.cast(day)
	_check(day.get_end_reason() == FishingDay.EndReason.NET_FULL and day.get_total_weight_kg() == 21, "Safe five-fish net ends at 21")
	_check(day.get_bait_remaining() == 1 and not day.can_cast(), "Full net blocks casting with bait left")
	source = FixedCatchSource.new([Fish.new(&"small", 2)])
	day = FishingDay.new(1, 40, 1, 5, 21, source)
	KeepEveryCatch.cast(day)
	_check(day.get_end_reason() == FishingDay.EndReason.BAIT_EMPTY and day.get_total_weight_kg() == 2, "Final bait catch is kept before ending")
	source = FixedCatchSource.new([Fish.new(&"bad", 0)])
	day = FishingDay.new(1, 40, 6, 5, 21, source)
	_check(KeepEveryCatch.cast(day).get_status() == CastResult.Status.SOURCE_ERROR, "Invalid source fish reported separately")
	_check(day.get_bait_remaining() == 6 and day.get_fish_count() == 0, "Invalid source does not corrupt day")
	var reentrant := ReentrantCatchSource.new()
	day = FishingDay.new(1, 40, 6, 5, 21, reentrant)
	reentrant.day = day
	KeepEveryCatch.cast(day)
	_check(reentrant.nested_status == CastResult.Status.REJECTED, "Source callback cannot reenter cast")
	_check(day.get_bait_remaining() == 5 and day.get_fish_count() == 1, "Reentry consumes only one bait and one slot")
	reentrant.day = null
	day = FishingDay.new(1, 40, 6, 5, 21)
	_check(not day.can_cast() and not KeepEveryCatch.cast(day).was_accepted(), "Unwired day safely rejects cast")


func _test_random_source() -> void:
	var config := LegacyTestConfig.make()
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261107
	var source := RandomCatchSource.new(config, rng)
	for pair in [[0.0, &"nothing"], [0.199999, &"nothing"], [0.2, &"small"], [0.749999, &"small"], [0.75, &"mid"], [0.899999, &"mid"], [0.9, &"big"], [0.979999, &"big"], [0.98, &"huge"], [0.999999, &"huge"]]:
		_check(source._pick_definition(pair[0]).species_id == pair[1], "Probability boundary %s" % pair[0])
	var second_rng := RandomNumberGenerator.new()
	second_rng.seed = 20261107
	var second := RandomCatchSource.new(config, second_rng)
	var valid_weights := true
	var same_sequence := true
	var counts := {&"nothing": 0, &"small": 0, &"mid": 0, &"big": 0, &"huge": 0}
	for index in range(10000):
		var fish := source.draw()
		var other := second.draw()
		if fish == null:
			counts[&"nothing"] += 1
			same_sequence = same_sequence and other == null
			continue
		counts[fish.get_species_id()] += 1
		var definition: FishDefinition
		for candidate in config.fish_definitions:
			if candidate.species_id == fish.get_species_id():
				definition = candidate
		valid_weights = valid_weights and fish.is_valid() and fish.get_weight_kg() >= definition.min_weight_kg and fish.get_weight_kg() <= definition.max_weight_kg
		same_sequence = same_sequence and other != null
		if other != null:
			same_sequence = same_sequence and other.get_species_id() == fish.get_species_id() and other.get_weight_kg() == fish.get_weight_kg()
	_check(valid_weights, "Seeded sample stays within all integer weight ranges")
	_check(same_sequence, "Same seed reproduces catch and weight sequence")
	for definition in config.fish_definitions:
		_check(absf(float(counts[definition.species_id]) / 10000.0 - definition.probability) < 0.025, "Seeded frequency sanity check %s" % definition.species_id)
	var custom := config.duplicate(true) as GameConfig
	source = RandomCatchSource.new(custom)
	custom.fish_definitions[1].species_id = &"changed"
	_check(source._pick_definition(0.3).species_id == &"small", "Catch source keeps independent definitions")
	custom = config.duplicate(true) as GameConfig
	for definition in custom.fish_definitions:
		definition.probability = 0.0
	custom.fish_definitions[2].probability = 1.0
	custom.fish_definitions[2].min_weight_kg = 7
	custom.fish_definitions[2].max_weight_kg = 7
	source = RandomCatchSource.new(custom)
	_check(source._pick_definition(0.0).species_id == &"mid" and source._pick_definition(0.999999).species_id == &"mid", "Zero probability outcomes skipped")
	_check(source.draw().get_weight_kg() == 7, "Single integer weight supported")


func _test_session() -> void:
	var config := LegacyTestConfig.make()
	var session := GameSession.new()
	session.start_new_game(config)
	var source := FixedCatchSource.new([Fish.new(&"huge", 21), Fish.new(&"small", 1)])
	_check(session.start_day(source), "Session accepts injected source")
	KeepEveryCatch.cast(session.get_current_day())
	KeepEveryCatch.cast(session.get_current_day())
	_check(session.get_state() == GameSession.State.DAY_ENDED, "Session observes day end without duplicated flags")
	_check(not session.start_day(), "Ended day cannot be silently reset")
	session.start_new_game(config)
	_check(session.start_day() and session.get_current_day().can_cast(), "Normal session creates random source")
	_check(KeepEveryCatch.cast(session.get_current_day()).was_accepted(), "Default source supports real casts")
	_check(session.get_coins() == 0 and session.get_day_number() == 1, "Casting does not settle income or advance day")
	var old_day := session.get_current_day()
	_check(old_day.get_bait_remaining() == 5, "Real cast consumes bait before restart")
	session.start_new_game(config)
	session.start_day()
	_check(session.get_current_day().get_bait_remaining() == 6 and session.get_current_day().get_fish_count() == 0, "Restart resets played day bait and catches")
	_check(old_day.get_bait_remaining() == 5, "Restart does not mutate old day reference")


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(label)
