extends SceneTree

var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func config() -> GameConfig:
	return load("res://config/default_game_config.tres").duplicate(true) as GameConfig

func fresh(sequence: Array[Fish], bait: int = 6) -> GameSession:
	var c := config()
	c.bait_per_day = bait
	var session := GameSession.new()
	check(session.start_new_game(c), "Configuration accepted")
	check(session.start_day(FixedCatchSource.new(sequence)), "Day starts")
	return session

func run() -> void:
	var c := config()
	check(c.validate().is_empty(), "Default configuration valid")
	check(c.daily_quotas == [180, 210, 240, 250, 260, 280, 300], "Rent curve")
	check(c.fish_definitions.size() == 10, "Ten species")
	var rewards := 0
	for definition in c.fish_definitions:
		check(not definition.is_empty_catch and definition.min_weight_kg > 0, "No empty outcome")
		rewards += definition.discovery_reward
	check(rewards == 98, "Catalogue reward budget")
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	for morning in range(100):
		var sea := SeaPoolCatchSource.new(c, rng)
		for cast in range(6):
			check(sea.draw() != null, "Every playable cast catches fish")
	var stocked := {&"sardine": 2, &"golden_tuna": 10}
	var sea := SeaPoolCatchSource.new(c, rng, stocked)
	var session := GameSession.new()
	session.start_new_game(c)
	session.start_day(sea)
	var day := session.get_current_day()
	day.cast()
	check(sea.get_remaining_total() == 11, "Cast removes fish immediately")
	check(day.get_total_weight_kg() == 0 and day.get_fish_count() == 0, "Catch waits for choice")
	check(day.get_bait_remaining() == 5, "Cast costs exactly one bait")
	check(not day.can_cast() and not day.return_to_shore(), "Pending choice blocks cast and return")
	check(not day.cast().was_accepted(), "Double cast rejected")
	check(session.settle_day() == null, "Cannot settle pending choice")
	check(day.resolve_catch(false), "Release accepted")
	check(sea.get_remaining_total() == 11 and day.get_fish_count() == 0, "Released fish never returns to sea")
	check(day.get_bait_remaining() == 5 and not day.resolve_catch(true), "No refund or double resolution")

	session = fresh([Fish.new(&"gold_butterflyfish", 3), Fish.new(&"gold_butterflyfish", 4)], 2)
	day = session.get_current_day()
	day.cast()
	check(day.was_last_catch_discovered() and session.preview_income() == 12, "Discovery pays on catch")
	check(session.get_catalog().is_discovered(&"gold_butterflyfish"), "Catch registers discovery")
	day.resolve_catch(false)
	day.cast()
	check(not day.was_last_catch_discovered() and day.get_discoveries().size() == 1, "No duplicate reward")
	check(not day.is_finished() and day.get_bait_remaining() == 0, "Final bait still waits for choice")
	day.resolve_catch(true)
	check(day.is_finished() and day.get_total_weight_kg() == 4, "Final bait resolves before settlement")
	var result := session.settle_day()
	check(result.get_income() == 76 and result.get_discovery_income() == 12, "Species sale plus discovery")
	check(session.settle_day().get_income() == 76 and session.get_coins() == 0, "Settlement idempotent, no savings cover")
	check(session.get_catalog().is_discovered(&"gold_butterflyfish"), "Discovery kept for the rest of the voyage")
	check(session.start_new_game(c), "Restart accepted")
	check(session.get_catalog().get_discovered_count() == 0, "New voyage starts with an empty field guide")
	session.start_day(FixedCatchSource.new([Fish.new(&"gold_butterflyfish", 3)]))
	session.get_current_day().cast()
	check(session.get_current_day().was_last_catch_discovered() and session.preview_income() == 12, "New voyage pays the discovery reward again")

	session = fresh([Fish.new(&"golden_tuna", 21)], 1)
	day = session.get_current_day()
	day.cast()
	check(session.preview_income() == 30, "Pending fish is not income yet; discovery is")
	day.resolve_catch(true)
	check(session.preview_income() == 870, "Preview uses settlement rules: species price, perfect and discovery")
	result = session.settle_day()
	check(result.is_perfect() and result.get_income() == 870, "420 sale doubled, 30 bonus not doubled")
	check(session.get_coins() == 690, "Rent deducted exactly once")
	session.settle_day()
	check(session.get_coins() == 690, "No double payment")
	check(session.advance_day() and not session.advance_day(), "Advance once")
	session.start_day(FixedCatchSource.new([Fish.new(&"sardine", 2)]))
	check(session.get_current_day().get_discoveries().is_empty() and session.preview_income() == 0, "Daily discovery income resets")

	session = fresh([Fish.new(&"golden_tuna", 20), Fish.new(&"sardine", 2)], 2)
	day = session.get_current_day()
	day.cast(); day.resolve_catch(true); day.cast()
	day.resolve_catch(true)
	check(session.preview_income() == 33, "Overflow preview retains discovery only")
	check(day.get_end_reason() == FishingDay.EndReason.BUST, "Keeping overweight fish busts")
	check(session.settle_day().get_income() == 33, "Bust loses sale, preserves discovery")

	session = fresh([Fish.new(&"sardine", 1), Fish.new(&"sardine", 1), Fish.new(&"sardine", 1), Fish.new(&"sardine", 1), Fish.new(&"sardine", 1)])
	day = session.get_current_day()
	for i in range(5):
		day.cast()
		check(not day.is_finished(), "Fifth fish choice precedes full-net ending")
		day.resolve_catch(true)
	check(day.get_end_reason() == FishingDay.EndReason.NET_FULL and day.get_bait_remaining() == 1, "Full net auto settles after choice")

	# Pending-catch edge cases: snapshots, empty outcomes and broken sources.
	day = FishingDay.new(1, 180, 6, 5, 21, FixedCatchSource.new([null, Fish.new(&"bad", 0), Fish.new(&"sardine", 3)]), FishCatalog.new())
	check(day.cast().get_status() == CastResult.Status.EMPTY, "Empty outcome is still a valid cast")
	check(day.get_bait_remaining() == 5 and day.get_pending_fish() == null and day.can_cast(), "Empty cast spends bait, leaves nothing to choose")
	check(day.cast().get_status() == CastResult.Status.SOURCE_ERROR and day.get_bait_remaining() == 5, "Invalid fish rejected without cost")
	var caught := day.cast()
	caught.get_fish()._weight_kg = 100
	day.get_pending_fish()._weight_kg = 100
	check(day.get_pending_fish().get_weight_kg() == 3, "Pending fish cannot be changed from outside")
	check(day.was_last_catch_discovered() and day.get_discoveries().size() == 1, "First sardine is a discovery")
	day.resolve_catch(false)
	check(day.return_to_shore() and not day.resolve_catch(true), "Resolution after return rejected")

	# Production scene and real signal wiring.
	var controller := load("res://scenes/main.tscn").instantiate() as GameController
	controller.cast_delay_seconds = 0.01
	controller.catch_source_factory = func() -> CatchSource: return FixedCatchSource.new([Fish.new(&"golden_tuna", 21)])
	root.add_child(controller)
	await process_frame
	var view := controller.get_node("GameView") as GameView
	(view.get_node("%StartButton") as Button).pressed.emit()
	(view.get_node("%CastButton") as Button).pressed.emit()
	await create_timer(0.05).timeout
	check(view.get_node("%CatchCard").visible, "Production catch opens popup")
	check((view.get_node("%CastButton") as Button).disabled and (view.get_node("%ReturnButton") as Button).disabled, "Popup blocks background gameplay")
	check(view.get_node("%CatchPrice").text == "420 gold" and view.get_node("%NewCatchLabel").visible, "Card displays sale value and new-discovery badge")
	(view.get_node("%KeepButton") as Button).pressed.emit()
	check(not view.get_node("%CatchCard").visible, "Keep closes popup")
	controller._on_return()
	check(controller.get_session().get_last_result().get_income() == 870, "Production controller settles species value")
	view.open_field_guide()
	check(view.get_node("%FieldGuide").visible and view.get_node("%CatalogDetails").text.contains("Collected 1 / 10"), "Field guide shows this voyage's discoveries")
	controller.queue_free()
	await process_frame
	print("Choices: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
