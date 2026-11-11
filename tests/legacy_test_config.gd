class_name LegacyTestConfig
extends RefCounted
## Old economy fixtures isolate unchanged lifecycle and forecast invariants.
## Production defaults are tested by test_foundation and test_choices.
static func make() -> GameConfig:
	var c := GameConfig.new()
	c.daily_quotas = [40, 50, 60, 70, 80, 90, 100]
	var ids := [&"nothing", &"small", &"mid", &"big", &"huge"]
	var probabilities := [0.2, 0.55, 0.15, 0.08, 0.02]
	var minimums := [0, 1, 5, 11, 17]
	var maximums := [0, 4, 10, 16, 21]
	for i in range(ids.size()):
		var d := FishDefinition.new()
		d.species_id = ids[i]
		d.display_name = String(ids[i])
		d.probability = probabilities[i]
		d.min_weight_kg = minimums[i]
		d.max_weight_kg = maximums[i]
		d.is_empty_catch = i == 0
		c.fish_definitions.append(d)
	return c
