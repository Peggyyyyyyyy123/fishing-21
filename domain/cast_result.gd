class_name CastResult
extends RefCounted
## Outcome of one cast request, separate from daily income settlement.

enum Status { REJECTED, EMPTY, CAUGHT, SOURCE_ERROR }

var _status: Status
var _fish: Fish


func _init(status: Status, fish: Fish = null) -> void:
	_status = status
	if fish != null:
		_fish = Fish.new(fish.get_species_id(), fish.get_weight_kg())


func get_status() -> Status:
	return _status


func was_accepted() -> bool:
	return _status == Status.EMPTY or _status == Status.CAUGHT


func get_fish() -> Fish:
	if _fish == null:
		return null
	return Fish.new(_fish.get_species_id(), _fish.get_weight_kg())
