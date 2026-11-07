extends SceneTree

class ReturningSource:
	extends CatchSource
	var day: FishingDay
	var returned: bool = true
	func draw() -> Fish:
		returned = day.return_to_shore()
		return Fish.new(&"small", 2)

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	_test_return_and_calculation()
	_test_session_settlement()
	print("Settlement: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _make_day(weights: Array[int], bait: int = 6, quota: int = 40) -> FishingDay:
	var catches: Array[Fish] = []
	for weight in weights:
		catches.append(null if weight == 0 else Fish.new(&"test", weight))
	var day := FishingDay.new(1, quota, bait, 5, 21, FixedCatchSource.new(catches))
	for weight in weights:
		day.cast()
	return day


func _test_return_and_calculation() -> void:
	var rules := SettlementRules.new(21, 10, 2, 0)
	_check(rules.calculate(null) == null, "Cannot calculate missing day")
	var day := _make_day([3, 4, 2])
	_check(rules.calculate(day) == null, "Cannot settle ongoing day")
	var bait := day.get_bait_remaining()
	_check(day.return_to_shore(), "Player can return with partial net")
	_check(day.get_end_reason() == FishingDay.EndReason.RETURNED, "Return records its own end reason")
	_check(day.get_bait_remaining() == bait, "Returning costs no bait")
	_check(not day.return_to_shore() and not day.cast().was_accepted(), "Repeated return and cast after return rejected")
	var result := rules.calculate(day)
	_check(result.get_income() == 90 and result.get_net_income() == 50, "Normal income minus quota")
	_check(result.is_passed() and result.get_coin_gain() == 50 and not result.is_perfect(), "Ordinary passing day")
	_check(result.get_day_number() == 1 and result.get_fish_count() == 3 and result.get_total_weight_kg() == 9, "Result captures day details")
	_check(rules.calculate(day).get_income() == 90 and day.get_bait_remaining() == bait, "Calculation is repeatable and does not mutate day")
	for weights in [[10, 11], [5, 5, 5, 5, 1], [17, 4], [21], [11, 5, 5]]:
		var typed_weights: Array[int] = []
		typed_weights.assign(weights)
		day = _make_day(typed_weights)
		if not day.is_finished():
			day.return_to_shore()
		result = rules.calculate(day)
		_check(result.is_perfect() and result.get_income() == 420 and result.get_coin_gain() == 380, "Perfect income for %s" % [weights])
	day = _make_day([20])
	day.return_to_shore()
	result = rules.calculate(day)
	_check(not result.is_perfect() and result.get_income() == 200, "20 kg does not receive multiplier")
	for weights in [[12, 10], [18, 4], [4, 4, 4, 4, 6]]:
		var typed_weights: Array[int] = []
		typed_weights.assign(weights)
		day = _make_day(typed_weights)
		_check(not day.return_to_shore(), "Returning cannot replace bust reason")
		result = rules.calculate(day)
		_check(result.get_income() == 0 and not result.is_perfect() and not result.is_passed(), "Bust produces zero income")
		_check(result.get_net_income() == -40 and result.get_coin_gain() == 0, "Failure reports shortfall without coin debit")
	day = _make_day([])
	_check(day.return_to_shore(), "Empty net may return")
	result = rules.calculate(day)
	_check(result.get_income() == 0 and not result.is_passed(), "Empty return fails positive quota")
	day = _make_day([4])
	day.return_to_shore()
	result = rules.calculate(day)
	_check(result.is_passed() and result.get_net_income() == 0 and result.get_coin_gain() == 0, "Exactly meeting quota passes")
	day = _make_day([4, 3, 2, 4, 3])
	_check(rules.calculate(day).get_income() == 160, "Full net settles without manual return")
	day = _make_day([0, 0, 0, 0, 0, 0])
	_check(rules.calculate(day).get_income() == 0, "Bait exhaustion settles empty net")
	day = _make_day([2], 1)
	_check(rules.calculate(day).get_income() == 20, "Last bait fish is included in settlement")
	var custom_rules := SettlementRules.new(21, 3, 3, 7)
	day = _make_day([21])
	day.return_to_shore()
	_check(custom_rules.calculate(day).get_income() == 189, "Price and multiplier come from supplied rules")
	day = _make_day([12, 10])
	_check(custom_rules.calculate(day).get_income() == 7, "Bust income comes from supplied rules")
	var source := ReturningSource.new()
	day = FishingDay.new(1, 40, 6, 5, 21, source)
	source.day = day
	day.cast()
	_check(not source.returned and not day.is_finished(), "Cannot return in middle of resolving a cast")
	source.day = null


func _test_session_settlement() -> void:
	var config := load("res://config/default_game_config.tres") as GameConfig
	var session := GameSession.new()
	_check(session.settle_day() == null and session.get_last_result() == null, "Unstarted session has no settlement")
	session.start_new_game(config)
	_check(session.settle_day() == null, "Cannot settle before day starts")
	session.start_day(FixedCatchSource.new([Fish.new(&"small", 4)]))
	session.get_current_day().cast()
	_check(session.settle_day() == null and session.get_coins() == 0, "No premature payment during active day")
	session.get_current_day().return_to_shore()
	var result := session.settle_day()
	_check(result.is_passed() and session.get_state() == GameSession.State.DAY_SETTLED, "Passing day enters settled state")
	_check(session.get_coins() == 0, "Exact quota pays zero surplus")
	_check(not session.start_day(), "Settlement does not silently start or advance next day")
	session.start_new_game(config)
	session.start_day(FixedCatchSource.new([Fish.new(&"mid", 10), Fish.new(&"big", 11)]))
	session.get_current_day().cast()
	session.get_current_day().cast()
	session.get_current_day().return_to_shore()
	result = session.settle_day()
	_check(result.get_income() == 420 and session.get_coins() == 380, "Session credits only surplus")
	var repeated := session.settle_day()
	_check(repeated.get_income() == 420 and session.get_coins() == 380, "Repeated settlement does not pay twice")
	result._income = 9999
	var snapshot := session.get_last_result()
	snapshot._quota = 0
	_check(session.get_last_result().get_income() == 420 and session.get_last_result().get_quota() == 40, "External result edits cannot corrupt stored result")
	_check(session.get_coins() == 380, "Result mutation cannot alter coins")
	session.start_new_game(config)
	_check(session.get_coins() == 0 and session.get_last_result() == null, "Restart clears real nonzero coins and result")
	session.start_day(FixedCatchSource.new([Fish.new(&"small", 3)]))
	session.get_current_day().cast()
	session.get_current_day().return_to_shore()
	result = session.settle_day()
	_check(not result.is_passed() and session.get_state() == GameSession.State.GAME_OVER, "Income below quota ends game")
	_check(session.get_coins() == 0 and not session.start_day(), "Failure gives no coins and blocks next day")
	_check(not session.settle_day().is_passed() and session.get_coins() == 0, "Repeated failing settlement is stable")
	var custom := config.duplicate(true) as GameConfig
	custom.price_per_kg = 5
	custom.daily_quotas[0] = 10
	session.start_new_game(custom)
	custom.price_per_kg = 100
	custom.daily_quotas[0] = 999
	session.start_day(FixedCatchSource.new([Fish.new(&"small", 4)]))
	session.get_current_day().cast()
	session.get_current_day().return_to_shore()
	result = session.settle_day()
	_check(result.get_income() == 20 and result.get_quota() == 10 and session.get_coins() == 10, "Settlement uses captured run config")
	_check(session.get_day_number() == 1, "Settlement preserves current day for result display")


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(label)
