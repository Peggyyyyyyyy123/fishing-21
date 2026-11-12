extends SceneTree
## Run after importing the project: Godot --headless --path . --script res://tests/test_foundation.gd

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	var config := load("res://config/default_game_config.tres") as GameConfig
	_check(config != null, "Default config loads")
	if config == null:
		quit(1)
		return
	_check(config.validate().is_empty(), "Default config is valid")
	_check(config.get_total_days() == 7, "Seven daily quotas")
	_check(config.fish_definitions.size() == 10, "Ten fish species")
	var expected_probabilities := [.20, .18, .16, .12, .10, .08, .06, .05, .03, .02]
	var expected_min := [1, 2, 3, 4, 6, 8, 2, 11, 5, 17]
	var expected_max := [3, 4, 5, 6, 9, 11, 4, 15, 8, 21]
	for index in range(config.fish_definitions.size()):
		var definition := config.fish_definitions[index]
		_check(is_equal_approx(definition.probability, expected_probabilities[index]), "Outcome probability %d" % index)
		_check(definition.min_weight_kg == expected_min[index] and definition.max_weight_kg == expected_max[index], "Outcome weight range %d" % index)
	var net := FishingNet.new(config.net_slots, config.weight_cap_kg)
	_check(net.get_fish_count() == 0 and net.get_total_weight_kg() == 0, "New net is empty")
	_check(net.add_fish(Fish.new(&"mid", 10)), "Accept 10 kg")
	_check(net.add_fish(Fish.new(&"big", 11)), "Accept 11 kg")
	_check(net.get_total_weight_kg() == 21 and not net.is_busted(), "Exactly 21 kg is safe")
	_check(not net.is_full(), "21 kg alone does not fill slots")
	_check(net.add_fish(Fish.new(&"small", 1)) and net.is_busted(), "Can continue at 21 kg and burst")
	_check(not net.add_fish(Fish.new(&"small", 1)), "Burst net rejects further additions")
	net = FishingNet.new(5, 21)
	net.add_fish(Fish.new(&"big", 12))
	net.add_fish(Fish.new(&"mid", 10))
	_check(net.get_total_weight_kg() == 22 and net.is_busted(), "12 plus 10 bursts")
	net = FishingNet.new(5, 21)
	for weight in [5, 5, 5, 5, 1]:
		_check(net.add_fish(Fish.new(&"test", weight)), "Accept catch in five-fish sequence")
	_check(net.is_full() and not net.is_busted() and net.get_total_weight_kg() == 21, "Full net at exactly 21 kg")
	_check(not net.add_fish(Fish.new(&"small", 1)), "Sixth fish rejected without changing weight")
	_check(net.get_fish_count() == 5 and net.get_total_weight_kg() == 21, "Rejected catch preserves net")
	net = FishingNet.new(5, 21)
	for weight in [4, 4, 4, 4, 6]:
		net.add_fish(Fish.new(&"test", weight))
	_check(net.is_full() and net.is_busted(), "Fifth catch can fill and burst net together")
	net = FishingNet.new(2, 8)
	_check(not net.add_fish(null) and not net.add_fish(Fish.new(&"small", 0)), "Null and zero-weight fish rejected")
	_check(not net.add_fish(Fish.new(&"", 2)) and not net.add_fish(Fish.new(&"small", -1)), "Missing species and negative weight rejected")
	var original := Fish.new(&"small", 4)
	net.add_fish(original)
	original._weight_kg = 100
	var snapshot := net.get_fish()
	snapshot[0]._weight_kg = 100
	snapshot.clear()
	_check(net.get_total_weight_kg() == 4 and net.get_fish_count() == 1, "External references cannot mutate stored catch")
	net.add_fish(Fish.new(&"small", 4))
	_check(net.is_full() and not net.is_busted(), "Net uses supplied capacity and weight limit")
	var fresh_net := FishingNet.new(5, 21)
	_check(fresh_net.get_fish_count() == 0, "New day can use independent net")
	var invalid := config.duplicate(true) as GameConfig
	invalid.fish_definitions[0].probability = 0.1
	_check(not invalid.validate().is_empty(), "Invalid probability sum rejected")
	_check(config.validate().is_empty(), "Validation test leaves default config unchanged")
	invalid = config.duplicate(true) as GameConfig
	invalid.fish_definitions[1].species_id = invalid.fish_definitions[0].species_id
	_check(not invalid.validate().is_empty(), "Duplicate outcome IDs rejected")
	invalid = config.duplicate(true) as GameConfig
	invalid.daily_quotas.clear()
	_check(not invalid.validate().is_empty(), "Missing daily quotas rejected")
	var empty := FishDefinition.new()
	empty.is_empty_catch = true
	_check(not empty.validate().is_empty(), "Empty catch cannot have positive weight")
	print("Foundation: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(label)
