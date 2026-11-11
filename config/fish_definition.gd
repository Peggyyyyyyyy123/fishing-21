class_name FishDefinition
extends Resource
## Configuration for one catch outcome. An empty catch is not a Fish instance.

@export var species_id: StringName = &"small"
@export var display_name: String = "Small fish"
@export_range(0.0, 1.0) var probability: float = 1.0
@export var min_weight_kg: int = 1
@export var max_weight_kg: int = 4
@export var is_empty_catch: bool = false
@export var rarity: String = "Common"
## Sale price for this species. 0 means "use GameConfig.price_per_kg".
@export var price_per_kg: int = 0
## One-time gold paid the first time this species enters the catalogue.
@export var discovery_reward: int = 0


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
	if price_per_kg < 0 or discovery_reward < 0:
		errors.append("Species price and discovery reward cannot be negative.")
	return errors
