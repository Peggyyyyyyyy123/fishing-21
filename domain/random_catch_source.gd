class_name RandomCatchSource
extends CatchSource
## Weighted catch selection followed by uniform integer weight selection.

var _definitions: Array[FishDefinition] = []
var _probability_sum: float = 0.0
var _rng: RandomNumberGenerator


func _init(config: GameConfig, rng: RandomNumberGenerator = null) -> void:
	assert(config != null and config.validate().is_empty(), "Catch source requires validated configuration.")
	for definition in config.fish_definitions:
		var snapshot := definition.duplicate(true) as FishDefinition
		_definitions.append(snapshot)
		_probability_sum += snapshot.probability
	_rng = rng if rng != null else RandomNumberGenerator.new()
	if rng == null:
		_rng.randomize()


func draw() -> Fish:
	# randf can include 1; the weighted selection contract uses [0, 1).
	var roll := minf(_rng.randf(), 1.0 - 1e-12)
	var definition := _pick_definition(roll)
	if definition.is_empty_catch:
		return null
	return Fish.new(
		definition.species_id,
		_rng.randi_range(definition.min_weight_kg, definition.max_weight_kg),
	)


func _pick_definition(roll: float) -> FishDefinition:
	assert(roll >= 0.0 and roll < 1.0, "Roll must be in [0, 1).")
	# Normalise sums within configuration tolerance to avoid an unassigned tail.
	var target := roll * _probability_sum
	var cumulative := 0.0
	var last_positive: FishDefinition
	for definition in _definitions:
		if definition.probability <= 0.0:
			continue
		last_positive = definition
		cumulative += definition.probability
		if target < cumulative:
			return definition
	return last_positive
