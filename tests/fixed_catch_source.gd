class_name FixedCatchSource
extends CatchSource
## Test-only sequence. Null entries are empty catches; exhaustion is an error.

var _sequence: Array[Fish] = []
var _draw_count: int = 0


func _init(sequence: Array[Fish]) -> void:
	for fish in sequence:
		_sequence.append(null if fish == null else Fish.new(fish.get_species_id(), fish.get_weight_kg()))


func draw() -> Fish:
	assert(_draw_count < _sequence.size(), "Fixed catch sequence exhausted.")
	var fish := _sequence[_draw_count]
	_draw_count += 1
	return null if fish == null else Fish.new(fish.get_species_id(), fish.get_weight_kg())


func get_draw_count() -> int:
	return _draw_count
