class_name FishCatalog
extends RefCounted
## The player's collection across voyages: which species were discovered and their catch records.
## Knows nothing about gold; SettlementRules prices discoveries. Persistence is in FishCatalogStore.

const SCHEMA_VERSION := 2

var _records: Dictionary = {}  # String species id -> {count, best_weight_kg, last_weight_kg}


## Builds a catalogue from saved data. Version 1 saves stored `true` per species:
## those stay discovered with no invented counts or weights.
static func from_dictionary(data: Dictionary) -> FishCatalog:
	var catalog := FishCatalog.new()
	for key in data:
		var value: Variant = data[key]
		var record := {"count": 0, "best_weight_kg": 0, "last_weight_kg": 0}
		if value is Dictionary:
			record["count"] = maxi(int(value.get("count", 0)), 0)
			record["best_weight_kg"] = maxi(int(value.get("best_weight_kg", 0)), 0)
			record["last_weight_kg"] = maxi(int(value.get("last_weight_kg", 0)), 0)
		elif value != true:
			continue
		catalog._records[String(key)] = record
	return catalog


func to_dictionary() -> Dictionary:
	return _records.duplicate(true)


func copy() -> FishCatalog:
	return FishCatalog.from_dictionary(to_dictionary())


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


## 0 when the species is undiscovered or was discovered before counts were recorded.
func get_catch_count(species_id: StringName) -> int:
	return int(_records.get(String(species_id), {}).get("count", 0))


## 0 when not recorded.
func get_best_weight_kg(species_id: StringName) -> int:
	return int(_records.get(String(species_id), {}).get("best_weight_kg", 0))
