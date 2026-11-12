extends SceneTree
## Godot --headless --path . --script res://tests/test_initialization.gd

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	var config := load("res://config/default_game_config.tres") as GameConfig
	_check(config != null, "Default configuration loads")
	if config == null:
		quit(1)
		return
	_test_start_lifecycle(config)
	_test_rejected_configuration(config)
	_test_run_isolation(config)
	_test_day_initialization()
	print("Initialization: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _test_start_lifecycle(config: GameConfig) -> void:
	var session := GameSession.new()
	_check(session.get_state() == GameSession.State.NOT_STARTED, "Session starts inactive")
	_check(session.get_day_number() == 0 and session.get_coins() == 0, "No day or coins before starting")
	_check(session.get_current_day() == null and session.get_total_days() == 0, "No runtime day or run length before starting")
	_check(not session.start_day(), "Cannot start a day before configuring a run")
	_check(session.start_new_game(config), "Start new game succeeds")
	_check(session.get_state() == GameSession.State.READY_FOR_DAY, "New game waits for day start")
	_check(session.get_day_number() == 1 and session.get_coins() == 0, "New game starts at day one with zero coins")
	_check(session.get_total_days() == 7 and session.get_current_day() == null, "Seven-day run has no day object until started")
	_check(session.start_day(), "First day starts")
	var first_day := session.get_current_day()
	_check(session.get_state() == GameSession.State.DAY_ACTIVE, "Day is active")
	_check(first_day.get_day_number() == 1 and first_day.get_quota() == 180, "First day uses first quota")
	_check(first_day.get_bait_remaining() == 6, "Day begins with six bait")
	_check(first_day.get_fish_count() == 0 and first_day.get_total_weight_kg() == 0, "Day begins with empty net")
	_check(not session.start_day(), "Duplicate day-start request rejected")
	_check(session.get_current_day() == first_day and session.get_day_number() == 1, "Duplicate start preserves active day identity")
	_check(session.start_new_game(config), "Explicit restart succeeds")
	_check(session.get_current_day() == null and session.get_coins() == 0, "Restart clears active day and coins")
	_check(session.start_day(), "Restarted first day starts")
	_check(session.get_current_day() != first_day, "Restart creates a new independent day")
	_check(session.get_current_day().get_bait_remaining() == 6, "Restart restores daily bait")


func _test_rejected_configuration(config: GameConfig) -> void:
	var session := GameSession.new()
	_check(not session.start_new_game(null), "Null config rejected")
	_check(session.get_state() == GameSession.State.NOT_STARTED, "Rejected start leaves session inactive")
	_check(not session.get_start_errors().is_empty(), "Rejected start provides diagnostic details")
	var errors := session.get_start_errors()
	errors.clear()
	_check(not session.get_start_errors().is_empty(), "Caller cannot clear stored diagnostics")
	var invalid := config.duplicate(true) as GameConfig
	invalid.bait_per_day = 0
	_check(not session.start_new_game(invalid), "Invalid daily bait rejected")
	invalid = config.duplicate(true) as GameConfig
	invalid.daily_quotas.clear()
	_check(not session.start_new_game(invalid), "Empty quota list rejected before indexing")
	_check(session.start_new_game(config) and session.start_day(), "Valid configuration recovers from rejected start")
	_check(session.get_start_errors().is_empty(), "Successful start clears earlier errors")
	var active_day := session.get_current_day()
	_check(not session.start_new_game(invalid), "Invalid restart rejected")
	_check(session.get_current_day() == active_day, "Invalid restart preserves current day")
	_check(session.get_state() == GameSession.State.DAY_ACTIVE and session.get_day_number() == 1, "Invalid restart preserves lifecycle")
	_check(session.get_total_days() == 7 and session.get_coins() == 0, "Invalid restart preserves run data")


func _test_run_isolation(config: GameConfig) -> void:
	var custom := config.duplicate(true) as GameConfig
	custom.bait_per_day = 3
	custom.daily_quotas = [15, 25]
	var first := GameSession.new()
	var second := GameSession.new()
	_check(first.start_new_game(custom), "Custom run config accepted")
	custom.bait_per_day = 9
	custom.daily_quotas[0] = 99
	custom.daily_quotas.append(30)
	_check(first.start_day(), "Day starts from captured configuration")
	_check(first.get_current_day().get_bait_remaining() == 3, "Source edits cannot change current run bait")
	_check(first.get_current_day().get_quota() == 15 and first.get_total_days() == 2, "Source array edits cannot change captured quotas")
	_check(second.start_new_game(custom) and second.start_day(), "Separate run uses updated configuration")
	_check(second.get_current_day().get_bait_remaining() == 9 and second.get_current_day().get_quota() == 99, "New run sees updated values")
	_check(first.get_current_day() != second.get_current_day(), "Sessions do not share day state")
	_check(config.bait_per_day == 6 and config.daily_quotas[0] == 180, "Default resource remains unchanged")


func _test_day_initialization() -> void:
	var day := FishingDay.new(3, 60, 4, 2, 8)
	_check(day.get_day_number() == 3 and day.get_quota() == 60, "Day stores supplied number and quota")
	_check(day.get_bait_remaining() == 4, "Day uses supplied bait instead of hardcoded default")
	var fish_snapshot := day.get_fish()
	fish_snapshot.append(Fish.new(&"small", 4))
	_check(day.get_fish_count() == 0 and day.get_total_weight_kg() == 0, "View cannot add catches by modifying snapshot")


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(label)
