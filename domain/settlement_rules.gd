class_name SettlementRules
extends RefCounted
## All money rules: species prices, the perfect-catch multiplier, bust income and discovery rewards.
## Calculates results without changing the day, session or coins.

var _definitions: Dictionary = {}  # StringName species id -> FishDefinition
var _weight_cap_kg: int
var _base_price_per_kg: int
var _perfect_multiplier: int
var _bust_income: int


func _init(
	definitions: Array[FishDefinition],
	weight_cap_kg: int,
	base_price_per_kg: int,
	perfect_multiplier: int,
	bust_income: int,
) -> void:
	assert(weight_cap_kg > 0 and base_price_per_kg > 0 and perfect_multiplier > 0 and bust_income >= 0)
	for definition in definitions:
		_definitions[definition.species_id] = definition
	_weight_cap_kg = weight_cap_kg
	_base_price_per_kg = base_price_per_kg
	_perfect_multiplier = perfect_multiplier
	_bust_income = bust_income


## A species' own price, or the base price when the species does not set one.
func get_price_per_kg(species_id: StringName) -> int:
	var definition: FishDefinition = _definitions.get(species_id)
	if definition == null or definition.price_per_kg <= 0:
		return _base_price_per_kg
	return definition.price_per_kg


## Sale value of one fish, before any multiplier.
func get_fish_value(fish: Fish) -> int:
	return 0 if fish == null else fish.get_weight_kg() * get_price_per_kg(fish.get_species_id())


func get_discovery_reward(species_id: StringName) -> int:
	var definition: FishDefinition = _definitions.get(species_id)
	return 0 if definition == null else definition.discovery_reward


## Income if the day ended now. Uses the same rule as calculate().
func preview_income(day: FishingDay) -> int:
	if day == null:
		return 0
	return _income(day, day.get_total_weight_kg() > _weight_cap_kg)


func calculate(day: FishingDay) -> DayResult:
	if day == null or not day.is_finished():
		return null
	var weight := day.get_total_weight_kg()
	var busted := day.get_end_reason() == FishingDay.EndReason.BUST or weight > _weight_cap_kg
	return DayResult.new(
		day.get_day_number(),
		day.get_end_reason(),
		weight,
		day.get_fish_count(),
		_income(day, busted),
		day.get_quota(),
		_is_perfect(weight, busted),
		_discovery_income(day),
	)


func _income(day: FishingDay, busted: bool) -> int:
	# Discovery rewards are paid even on a bust and are never multiplied.
	var sale := _bust_income
	if not busted:
		sale = 0
		for fish in day.get_fish():
			sale += get_fish_value(fish)
		if _is_perfect(day.get_total_weight_kg(), busted):
			sale *= _perfect_multiplier
	return sale + _discovery_income(day)


func _is_perfect(weight_kg: int, busted: bool) -> bool:
	return not busted and weight_kg == _weight_cap_kg


func _discovery_income(day: FishingDay) -> int:
	var total := 0
	for fish in day.get_discoveries():
		total += get_discovery_reward(fish.get_species_id())
	return total
