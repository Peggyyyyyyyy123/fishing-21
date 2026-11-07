class_name FishDefinition
extends Resource
## Configuration for one catch outcome. An empty catch is not a Fish instance.

@export var species_id: StringName = &"small"
@export var display_name: String = "Small fish"
@export_range(0.0, 1.0) var probability: float = 1.0
@export var min_weight_kg: int = 1
@export var max_weight_kg: int = 4
@export var is_empty_catch: bool = false


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if species_id == &"":
		errors.append("Catch outcome must have an ID.")
	if not is_finite(probability) or probability < 0.0 or probability > 1.0:
		errors.append("Probability must be finite and between 0 and 1.")
	if is_empty_catch:
		if min_weight_kg != 0 or max_weight_kg != 0:
			errors.append("Empty catches must have zero weight.")
	elif min_weight_kg < 1 or max_weight_kg < min_weight_kg:
		errors.append("Fish weights must form a positive integer interval.")
	return errors
