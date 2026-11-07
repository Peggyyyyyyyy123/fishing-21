class_name Fish
extends RefCounted
## One caught fish. Access through getters; no mutation API is exposed.

var _species_id: StringName
var _weight_kg: int


func _init(species_id: StringName, weight_kg: int) -> void:
	_species_id = species_id
	_weight_kg = weight_kg


func get_species_id() -> StringName:
	return _species_id


func get_weight_kg() -> int:
	return _weight_kg


func is_valid() -> bool:
	return _species_id != &"" and _weight_kg > 0
