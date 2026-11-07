class_name FishingNet
extends RefCounted
## Owns a day's catch. Settlement and bait belong to other objects.

var _slot_limit: int
var _weight_cap_kg: int
var _fish: Array[Fish] = []


func _init(slot_limit: int, weight_cap_kg: int) -> void:
	assert(slot_limit > 0, "Net slot limit must be positive.")
	assert(weight_cap_kg > 0, "Net weight limit must be positive.")
	_slot_limit = slot_limit
	_weight_cap_kg = weight_cap_kg


func add_fish(fish: Fish) -> bool:
	if fish == null or not fish.is_valid() or is_full() or is_busted():
		return false
	# Crossing the limit must be accepted: that catch causes the net to burst.
	# Copy the value so outside references cannot change a catch already in the net.
	_fish.append(Fish.new(fish.get_species_id(), fish.get_weight_kg()))
	return true


func get_fish_count() -> int:
	return _fish.size()


func get_total_weight_kg() -> int:
	var total := 0
	for fish in _fish:
		total += fish.get_weight_kg()
	return total


func is_full() -> bool:
	return get_fish_count() >= _slot_limit


func is_busted() -> bool:
	return get_total_weight_kg() > _weight_cap_kg


func get_fish() -> Array[Fish]:
	var snapshot: Array[Fish] = []
	for fish in _fish:
		snapshot.append(Fish.new(fish.get_species_id(), fish.get_weight_kg()))
	return snapshot
