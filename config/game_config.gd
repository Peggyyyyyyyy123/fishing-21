class_name GameConfig
extends Resource
## Shared configuration. Treat loaded resources as read-only during gameplay.

@export var net_slots: int = 5
@export var bait_per_day: int = 6
@export var weight_cap_kg: int = 21
## Base sale price per kg for species that do not set their own price.
@export var price_per_kg: int = 10
@export var perfect_multiplier: int = 2
@export var bust_income: int = 0
## Outcomes stocked in each day's visible sea, drawn without replacement. 0 = independent draws.
@export var sea_pool_size: int = 12
@export var daily_quotas: Array[int] = [180, 210, 240, 250, 260, 280, 300]
@export var fish_definitions: Array[FishDefinition] = []


func get_total_days() -> int:
	# The quota list is the single source of truth for the run length.
	return daily_quotas.size()


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if net_slots < 1 or bait_per_day < 1 or weight_cap_kg < 1:
		errors.append("Net capacity, bait and weight limit must be positive.")
	if price_per_kg < 1 or perfect_multiplier < 1 or bust_income < 0:
		errors.append("Price and multiplier must be positive; bust income cannot be negative.")
	if sea_pool_size < 0 or (sea_pool_size > 0 and sea_pool_size < bait_per_day):
		errors.append("Sea pool size must be 0 (independent draws) or at least the daily bait.")
	if daily_quotas.is_empty():
		errors.append("At least one daily quota is required.")
	for quota in daily_quotas:
		if quota < 0:
			errors.append("Daily quotas cannot be negative.")
	if fish_definitions.is_empty():
		errors.append("At least one catch outcome is required.")
	var probability_sum := 0.0
	var ids: Dictionary = {}
	for definition in fish_definitions:
		if definition == null:
			errors.append("Catch outcomes cannot be null.")
			continue
		errors.append_array(definition.validate())
		if ids.has(definition.species_id):
			errors.append("Catch outcome IDs must be unique: %s" % definition.species_id)
		ids[definition.species_id] = true
		probability_sum += definition.probability
	if not is_finite(probability_sum) or absf(probability_sum - 1.0) > 0.000001:
		errors.append("Catch probabilities must add up to 1.")
	return errors
