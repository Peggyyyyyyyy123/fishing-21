class_name FishingDay
extends RefCounted
## Owns one day's runtime state: bait, the catch waiting for a keep/release choice,
## the net and how the day ended. Each day starts with a fresh net. Money is not
## decided here; SettlementRules prices the net and today's discoveries.

enum EndReason { NONE, BUST, NET_FULL, BAIT_EMPTY, RETURNED }

var _end_reason: EndReason = EndReason.NONE
var _catch_source: CatchSource
var _is_resolving: bool = false  # Rejects re-entrant casts while the source is drawing.
var _day_number: int
var _quota: int
var _bait_remaining: int
var _net: FishingNet
var _catalog: FishCatalog
var _pending_fish: Fish
var _last_catch_discovered: bool = false
var _discoveries: Array[Fish] = []


## `catalog` is shared with the session so discoveries persist across days; null disables recording.
func _init(
	day_number: int,
	quota: int,
	bait_count: int,
	net_slots: int,
	weight_cap_kg: int,
	catch_source: CatchSource = null,
	catalog: FishCatalog = null,
) -> void:
	assert(day_number > 0, "Day number must be positive.")
	assert(quota >= 0, "Daily quota cannot be negative.")
	assert(bait_count > 0, "Daily bait must be positive.")
	_catch_source = catch_source
	_catalog = catalog
	_day_number = day_number
	_quota = quota
	_bait_remaining = bait_count
	_net = FishingNet.new(net_slots, weight_cap_kg)
func get_day_number() -> int:
	return _day_number


func get_quota() -> int:
	return _quota


func get_bait_remaining() -> int:
	return _bait_remaining


func get_fish_count() -> int:
	return _net.get_fish_count()


func get_total_weight_kg() -> int:
	return _net.get_total_weight_kg()


func get_fish() -> Array[Fish]:
	# Presentation gets a snapshot, not direct access to the mutable net.
	return _net.get_fish()


func get_next_cast_chances() -> Dictionary:
	return {} if _catch_source == null else _catch_source.get_next_draw_chances()


func get_sea_initial_counts() -> Dictionary:
	return {} if _catch_source == null else _catch_source.get_initial_counts()


func get_sea_remaining_counts() -> Dictionary:
	return {} if _catch_source == null else _catch_source.get_remaining_counts()


func can_cast() -> bool:
	return (
		_catch_source != null
		and not _is_resolving
		and not is_finished()
		and _pending_fish == null
		and _bait_remaining > 0
		and not _net.is_full()
		and not _net.is_busted()
	)


## Spends one bait and draws. A caught fish waits in get_pending_fish() until resolve_catch().
func cast() -> CastResult:
	if not can_cast():
		return CastResult.new(CastResult.Status.REJECTED)
	_is_resolving = true
	_bait_remaining -= 1
	var fish := _catch_source.draw()
	_is_resolving = false
	_last_catch_discovered = false
	if fish == null:
		# Empty outcome: bait is spent, nothing to choose.
		_update_end_reason()
		return CastResult.new(CastResult.Status.EMPTY)
	if not fish.is_valid():
		# A broken source must not turn an invalid fish into a paid cast.
		_bait_remaining += 1
		return CastResult.new(CastResult.Status.SOURCE_ERROR)
	_pending_fish = Fish.new(fish.get_species_id(), fish.get_weight_kg())
	# Released fish count too: the catalogue records every catch.
	if _catalog != null and _catalog.record_catch(fish):
		_last_catch_discovered = true
		_discoveries.append(Fish.new(fish.get_species_id(), fish.get_weight_kg()))
	return CastResult.new(CastResult.Status.CAUGHT, fish)


func get_pending_fish() -> Fish:
	return null if _pending_fish == null else Fish.new(_pending_fish.get_species_id(), _pending_fish.get_weight_kg())


## Keep puts the pending fish in the net (it may break the net); release lets it go.
## Either way the bait stays spent and the fish does not return to the sea.
func resolve_catch(keep: bool) -> bool:
	if _pending_fish == null or is_finished():
		return false
	if keep and not _net.add_fish(_pending_fish):
		return false
	_pending_fish = null
	_update_end_reason()
	return true


## True when the most recent cast caught a species for the first time.
func was_last_catch_discovered() -> bool:
	return _last_catch_discovered


## Species first discovered today, in catch order (snapshots).
func get_discoveries() -> Array[Fish]:
	var snapshot: Array[Fish] = []
	for fish in _discoveries:
		snapshot.append(Fish.new(fish.get_species_id(), fish.get_weight_kg()))
	return snapshot


func is_finished() -> bool:
	return _end_reason != EndReason.NONE


func get_end_reason() -> EndReason:
	return _end_reason


func _update_end_reason() -> void:
	# Bust takes precedence when the final slot or bait is used by that catch.
	if _net.is_busted():
		_end_reason = EndReason.BUST
	elif _net.is_full():
		_end_reason = EndReason.NET_FULL
	elif _bait_remaining == 0:
		_end_reason = EndReason.BAIT_EMPTY


func return_to_shore() -> bool:
	# Empty nets may return; not twice, not mid-cast, not before choosing keep or release.
	if _is_resolving or _pending_fish != null or is_finished():
		return false
	_end_reason = EndReason.RETURNED
	return true
