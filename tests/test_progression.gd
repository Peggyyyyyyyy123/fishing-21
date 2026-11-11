extends SceneTree

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	_test_seven_day_victory()
	_test_failure_on_each_day()
	_test_savings_cannot_pay_rent()
	_test_transition_guards()
	_test_custom_run_lengths()
	print("Progression: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _config() -> GameConfig:
	return LegacyTestConfig.make()


func _start_and_catch(session: GameSession, weights: Array[int]) -> FishingDay:
	var catches: Array[Fish] = []
	for weight in weights:
		catches.append(null if weight == 0 else Fish.new(&"test", weight))
	_check(session.start_day(FixedCatchSource.new(catches)), "Start day %d" % session.get_day_number())
	var day := session.get_current_day()
	_check(day.get_bait_remaining() == 6 and day.get_fish_count() == 0 and day.get_total_weight_kg() == 0, "Each day starts with fresh bait and net")
	for weight in weights:
		_check(KeepEveryCatch.cast(day).was_accepted(), "Scheduled cast accepted")
	return day


func _finish(day: FishingDay) -> void:
	if not day.is_finished():
		_check(day.return_to_shore(), "Return ends active day")


func _test_seven_day_victory() -> void:
	var session := GameSession.new()
	_check(session.start_new_game(_config()), "Start seven-day run")
	var sequences := [[3, 4, 2], [10, 11], [4, 3, 2, 4, 3], [0, 0, 0, 0, 0, 7], [8], [9], [10]]
	var incomes := [90, 420, 160, 70, 80, 90, 100]
	var expected_coins := 0
	var previous_day: FishingDay
	var previous_result: DayResult
	for index in range(7):
		var weights: Array[int] = []
		weights.assign(sequences[index])
		_check(session.get_day_number() == index + 1, "Days remain ordered")
		var day := _start_and_catch(session, weights)
		_check(day != previous_day, "Day object is not reused")
		_check(day.get_quota() == 40 + index * 10, "Correct quota for each day")
		if previous_day != null:
			_check(not KeepEveryCatch.cast(previous_day).was_accepted(), "Old day stays closed")
			_check(previous_result.get_day_number() == index, "Previous result snapshot remains stable")
		_finish(day)
		var result := session.settle_day()
		expected_coins += incomes[index] - (40 + index * 10)
		_check(result != null and result.is_passed() and result.get_income() == incomes[index], "Daily income matches scheduled scenario")
		_check(session.get_coins() == expected_coins, "Only daily surplus accumulates")
		_check(session.settle_day().get_income() == incomes[index] and session.get_coins() == expected_coins, "Repeated settlement never pays twice")
		_check(session.get_day_number() == index + 1, "Result display keeps completed day number")
		if index < 6:
			_check(session.get_state() == GameSession.State.DAY_SETTLED and session.can_advance_day(), "Successful non-final day enables continue")
			_check(session.advance_day(), "Continue advances once")
			_check(session.get_current_day() == null and session.get_last_result() == null, "Advance clears day and cached settlement")
			_check(session.get_state() == GameSession.State.READY_FOR_DAY, "Next day waits for explicit start")
			_check(not session.advance_day() and session.get_day_number() == index + 2, "Duplicate continue cannot skip a day")
			_check(session.settle_day() == null and session.get_coins() == expected_coins, "Old result cannot settle the new day")
		previous_day = day
		previous_result = result
	_check(session.get_state() == GameSession.State.VICTORY, "Seventh passing day wins immediately at settlement")
	_check(session.get_coins() == 520, "Mixed seven-day scenario accumulates 520 coins")
	_check(not session.can_advance_day() and not session.advance_day() and not session.start_day(), "Victory has no eighth day")
	_check(session.get_day_number() == 7 and session.get_last_result().get_day_number() == 7, "Victory preserves final day and result")
	_check(not KeepEveryCatch.cast(session.get_current_day()).was_accepted(), "Victory day cannot cast")
	_check(session.start_new_game(_config()), "Can restart after victory")
	_check(session.get_state() == GameSession.State.READY_FOR_DAY and session.get_day_number() == 1, "Victory restart returns to first day")
	_check(session.get_coins() == 0 and session.get_current_day() == null and session.get_last_result() == null, "Victory restart clears completed run state")


func _test_failure_on_each_day() -> void:
	for failure_day in range(1, 8):
		var session := GameSession.new()
		session.start_new_game(_config())
		var expected_coins := 0
		for number in range(1, failure_day):
			var day := _start_and_catch(session, [21])
			_finish(day)
			session.settle_day()
			expected_coins += 420 - (30 + number * 10)
			_check(session.advance_day(), "Earlier passing day advances")
		var day := _start_and_catch(session, [])
		_finish(day)
		var result := session.settle_day()
		_check(not result.is_passed() and session.get_state() == GameSession.State.GAME_OVER, "Failure on day %d ends run" % failure_day)
		_check(session.get_coins() == expected_coins, "Failure never spends accumulated savings")
		_check(session.get_day_number() == failure_day, "Failure preserves exact failing day")
		_check(not session.advance_day() and not session.start_day(), "Failure blocks continue and day start")
		_check(session.settle_day().get_income() == 0 and session.get_coins() == expected_coins, "Failed settlement remains idempotent")
		_check(session.start_new_game(_config()) and session.get_coins() == 0, "Restart after failure clears savings")


func _test_savings_cannot_pay_rent() -> void:
	var session := GameSession.new()
	session.start_new_game(_config())
	var day := _start_and_catch(session, [21])
	_finish(day)
	session.settle_day()
	_check(session.get_coins() == 380, "First day builds savings")
	session.advance_day()
	day = _start_and_catch(session, [4])
	_finish(day)
	var result := session.settle_day()
	_check(result.get_income() == 40 and result.get_quota() == 50 and result.get_net_income() == -10, "Second day is ten below rent")
	_check(session.get_state() == GameSession.State.GAME_OVER and session.get_coins() == 380, "Savings cannot cover ten-coin shortfall")
	session.start_new_game(_config())
	day = _start_and_catch(session, [21])
	_finish(day)
	session.settle_day()
	session.advance_day()
	day = _start_and_catch(session, [12, 10])
	result = session.settle_day()
	_check(result.get_income() == 0 and session.get_state() == GameSession.State.GAME_OVER, "Bust fails with savings")
	_check(session.get_coins() == 380, "Bust does not debit savings")


func _test_transition_guards() -> void:
	var session := GameSession.new()
	_check(not session.can_advance_day() and not session.advance_day(), "Cannot advance before game starts")
	session.start_new_game(_config())
	_check(not session.advance_day(), "Cannot skip unstarted first day")
	var day := _start_and_catch(session, [4])
	_check(not session.advance_day(), "Cannot advance active day")
	_finish(day)
	_check(not session.advance_day(), "Cannot advance before settlement")
	session.settle_day()
	_check(session.advance_day(), "Settled success unlocks advancement")
	_check(not session.advance_day() and session.get_day_number() == 2, "Repeated advancement before day start rejected")
	_check(session.settle_day() == null, "No stale first-day settlement on day two")
	day = _start_and_catch(session, [5])
	_check(session.settle_day() == null, "Unfinished second day cannot return old settlement")
	_finish(day)
	_check(session.settle_day().get_day_number() == 2, "Second day produces its own result")


func _test_custom_run_lengths() -> void:
	for length in [1, 2, 8]:
		var config := _config().duplicate(true) as GameConfig
		config.daily_quotas.clear()
		for index in range(length):
			config.daily_quotas.append(40)
		var session := GameSession.new()
		session.start_new_game(config)
		for index in range(length):
			var day := _start_and_catch(session, [4])
			_finish(day)
			session.settle_day()
			if index < length - 1:
				_check(session.get_state() != GameSession.State.VICTORY and session.advance_day(), "Custom run does not win early")
		_check(session.get_state() == GameSession.State.VICTORY and session.get_day_number() == length, "Victory follows configured run length %d" % length)
		_check(not session.advance_day(), "Custom final day cannot advance")


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(label)
