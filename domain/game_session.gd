class_name GameSession
extends RefCounted
## Owns run lifecycle, day number and coins. No scene-tree dependencies.

enum State { NOT_STARTED, READY_FOR_DAY, DAY_ACTIVE, DAY_ENDED }

var _state: State = State.NOT_STARTED
var _config: GameConfig
var _day_number: int = 0
var _coins: int = 0
var _current_day: FishingDay
var _start_errors := PackedStringArray()


func start_new_game(config: GameConfig) -> bool:
	# Validate before replacing a running session, so a failed restart is harmless.
	_start_errors.clear()
	if config == null:
		_start_errors.append("A game configuration is required.")
		return false
	_start_errors = config.validate()
	if not _start_errors.is_empty():
		return false
	# Freeze this run's inputs; editing the source resource affects only later runs.
	_config = config.duplicate(true) as GameConfig
	_day_number = 1
	_coins = 0
	_current_day = null
	_state = State.READY_FOR_DAY
	return true


func start_day(catch_source: CatchSource = null) -> bool:
	# Repeated button/input events must not reset bait or replace an active net.
	if _state != State.READY_FOR_DAY:
		return false
	var source := catch_source
	if source == null:
		source = RandomCatchSource.new(_config)
	_current_day = FishingDay.new(
		_day_number,
		_config.daily_quotas[_day_number - 1],
		_config.bait_per_day,
		_config.net_slots,
		_config.weight_cap_kg,
		source,
	)
	_state = State.DAY_ACTIVE
	return true


func get_state() -> State:
	# Derive day completion instead of maintaining a second mutable end flag.
	if _state == State.DAY_ACTIVE and _current_day.is_finished():
		return State.DAY_ENDED
	return _state


func get_day_number() -> int:
	return _day_number


func get_coins() -> int:
	return _coins


func get_total_days() -> int:
	return 0 if _config == null else _config.get_total_days()


func get_current_day() -> FishingDay:
	return _current_day


func get_start_errors() -> PackedStringArray:
	return _start_errors.duplicate()
