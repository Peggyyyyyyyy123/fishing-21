class_name CatchForecast
extends RefCounted
## Exact odds for the next cast, from the source's outcome chances and each
## outcome's uniform integer weight range. Uses only information shown to the player.

var _bust_chance: float = 0.0
var _perfect_chance: float = 0.0
var _empty_chance: float = 0.0
var _room_kg: int = 0


static func calculate(
	definitions: Array[FishDefinition],
	chances: Dictionary,
	current_weight_kg: int,
	weight_cap_kg: int,
) -> CatchForecast:
	if chances.is_empty():
		return null
	var forecast := CatchForecast.new()
	var room := weight_cap_kg - current_weight_kg
	forecast._room_kg = room
	for definition in definitions:
		var chance: float = chances.get(definition.species_id, 0.0)
		if chance <= 0.0:
			continue
		if definition.is_empty_catch:
			forecast._empty_chance += chance
			continue
		var count := definition.max_weight_kg - definition.min_weight_kg + 1
		# Weights strictly above the remaining room break the net.
		var over := clampi(definition.max_weight_kg - maxi(room, definition.min_weight_kg - 1), 0, count)
		forecast._bust_chance += chance * over / count
		if room >= definition.min_weight_kg and room <= definition.max_weight_kg:
			forecast._perfect_chance += chance / count
	return forecast


func get_bust_chance() -> float:
	return _bust_chance


func get_perfect_chance() -> float:
	return _perfect_chance


func get_empty_chance() -> float:
	return _empty_chance


func get_safe_chance() -> float:
	return 1.0 - _bust_chance


## Kilograms that can still be added without breaking the net.
func get_room_kg() -> int:
	return _room_kg
