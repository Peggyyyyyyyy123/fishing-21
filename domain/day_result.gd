class_name DayResult
extends RefCounted
## Value snapshot of a finished day. Negative net income is a shortfall, not a coin debit.

var _day_number: int
var _end_reason: FishingDay.EndReason
var _weight_kg: int
var _fish_count: int
var _income: int
var _quota: int
var _perfect: bool
var _discovery_income: int


func _init(
	day_number: int,
	end_reason: FishingDay.EndReason,
	weight_kg: int,
	fish_count: int,
	income: int,
	quota: int,
	perfect: bool,
	discovery_income: int = 0,
) -> void:
	_day_number = day_number
	_end_reason = end_reason
	_weight_kg = weight_kg
	_fish_count = fish_count
	_income = income
	_quota = quota
	_perfect = perfect
	_discovery_income = discovery_income


func get_day_number() -> int:
	return _day_number


func get_end_reason() -> FishingDay.EndReason:
	return _end_reason


func get_total_weight_kg() -> int:
	return _weight_kg


func get_fish_count() -> int:
	return _fish_count


func get_discovery_income() -> int:
	return _discovery_income


func get_income() -> int:
	return _income


func get_quota() -> int:
	return _quota


func is_perfect() -> bool:
	return _perfect


func is_passed() -> bool:
	return _income >= _quota


func get_net_income() -> int:
	return _income - _quota


func get_coin_gain() -> int:
	return get_net_income() if is_passed() else 0


func copy() -> DayResult:
	return DayResult.new(_day_number, _end_reason, _weight_kg, _fish_count, _income, _quota, _perfect, _discovery_income)
