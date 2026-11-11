class_name SeaPoolCatchSource
extends CatchSource
## A finite daily sea. Outcomes are stocked at dawn and drawn without replacement,
## so every cast changes the odds of the next one. The stocked counts are public
## information; a fish's exact weight is rolled within its range when it is caught.

var _definitions: Array[FishDefinition] = []
var _initial_counts: Dictionary = {}
var _remaining_counts: Dictionary = {}
var _rng: RandomNumberGenerator


## `stocked_counts` (species_id -> count) replaces random stocking, for tests and scripted days.
func _init(config: GameConfig, rng: RandomNumberGenerator = null, stocked_counts: Dictionary = {}) -> void:
	assert(config != null and config.validate().is_empty(), "Sea pool requires validated configuration.")
	_rng = rng if rng != null else RandomNumberGenerator.new()
	if rng == null:
		_rng.randomize()
	for definition in config.fish_definitions:
		_definitions.append(definition.duplicate(true) as FishDefinition)
		_initial_counts[definition.species_id] = 0
	if stocked_counts.is_empty():
		_stock(config.sea_pool_size)
	else:
		for species_id in stocked_counts:
			assert(_initial_counts.has(species_id), "Unknown species in stocked counts: %s" % species_id)
			_initial_counts[species_id] = maxi(int(stocked_counts[species_id]), 0)
	_remaining_counts = _initial_counts.duplicate()


func draw() -> Fish:
	var total := get_remaining_total()
	if total <= 0:
		# Validation keeps the pool at least as large as daily bait; a drained sea yields nothing.
		return null
	var pick := _rng.randi_range(0, total - 1)
	for definition in _definitions:
		var count: int = _remaining_counts[definition.species_id]
		if pick < count:
			_remaining_counts[definition.species_id] = count - 1
			if definition.is_empty_catch:
				return null
			return Fish.new(definition.species_id, _rng.randi_range(definition.min_weight_kg, definition.max_weight_kg))
		pick -= count
	return null


func get_next_draw_chances() -> Dictionary:
	var chances := {}
	var total := get_remaining_total()
	if total <= 0:
		return chances
	for definition in _definitions:
		chances[definition.species_id] = float(_remaining_counts[definition.species_id]) / total
	return chances


func get_initial_counts() -> Dictionary:
	return _initial_counts.duplicate()


func get_remaining_counts() -> Dictionary:
	return _remaining_counts.duplicate()


func get_remaining_total() -> int:
	var total := 0
	for species_id in _remaining_counts:
		total += _remaining_counts[species_id]
	return total


func _stock(pool_size: int) -> void:
	# Each entry follows the configured catch distribution, so a single draw keeps
	# the same overall odds while each day gets its own visible sea.
	var probability_sum := 0.0
	for definition in _definitions:
		probability_sum += maxf(definition.probability, 0.0)
	for index in range(pool_size):
		var target := minf(_rng.randf(), 1.0 - 1e-12) * probability_sum
		var cumulative := 0.0
		var picked: FishDefinition
		for definition in _definitions:
			if definition.probability <= 0.0:
				continue
			picked = definition
			cumulative += definition.probability
			if target < cumulative:
				break
		_initial_counts[picked.species_id] += 1
