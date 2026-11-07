class_name SettlementRules
extends RefCounted
## Calculates a result without changing the day, session or coins.

var _weight_cap_kg: int
var _price_per_kg: int
var _perfect_multiplier: int
var _bust_income: int


func _init(weight_cap_kg: int, price_per_kg: int, perfect_multiplier: int, bust_income: int) -> void:
	assert(weight_cap_kg > 0 and price_per_kg > 0 and perfect_multiplier > 0 and bust_income >= 0)
	_weight_cap_kg = weight_cap_kg
	_price_per_kg = price_per_kg
	_perfect_multiplier = perfect_multiplier
	_bust_income = bust_income


func calculate(day: FishingDay) -> DayResult:
	if day == null or not day.is_finished():
		return null
	var weight := day.get_total_weight_kg()
	var busted := day.get_end_reason() == FishingDay.EndReason.BUST or weight > _weight_cap_kg
	var perfect := not busted and weight == _weight_cap_kg
	var income := _bust_income if busted else weight * _price_per_kg
	if perfect:
		income *= _perfect_multiplier
	return DayResult.new(
		day.get_day_number(),
		day.get_end_reason(),
		weight,
		day.get_fish_count(),
		income,
		day.get_quota(),
		perfect,
	)
