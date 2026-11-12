class_name FishCatalog
extends RefCounted
## The voyage's field guide: which species were discovered and their catch records.
## Knows nothing about gold; SettlementRules prices discoveries. A new voyage starts a new catalogue.

var _records: Dictionary = {}  # String species id -> {count, best_weight_kg, last_weight_kg}


func copy() -> FishCatalog:
	var catalog := FishCatalog.new()
	catalog._records = _records.duplicate(true)
	return catalog


## Records a caught fish (kept or released). Returns true on the first discovery of its species.
func record_catch(fish: Fish) -> bool:
	if fish == null or not fish.is_valid():
		return false
	var id := String(fish.get_species_id())
	var first := not _records.has(id)
	var record: Dictionary = _records.get(id, {"count": 0, "best_weight_kg": 0, "last_weight_kg": 0})
	record["count"] = int(record["count"]) + 1
	record["best_weight_kg"] = maxi(int(record["best_weight_kg"]), fish.get_weight_kg())
	record["last_weight_kg"] = fish.get_weight_kg()
	_records[id] = record
	return first


func is_discovered(species_id: StringName) -> bool:
	return _records.has(String(species_id))


func get_discovered_count() -> int:
	return _records.size()


## 0 when the species is undiscovered.
func get_catch_count(species_id: StringName) -> int:
	return int(_records.get(String(species_id), {}).get("count", 0))


## 0 when the species is undiscovered.
func get_best_weight_kg(species_id: StringName) -> int:
	return int(_records.get(String(species_id), {}).get("best_weight_kg", 0))
