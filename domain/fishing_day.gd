class_name FishingDay
extends RefCounted
## Owns one day's runtime state. Each day starts with a fresh net.

enum EndReason { NONE, BUST, NET_FULL, BAIT_EMPTY, RETURNED }

var _end_reason: EndReason = EndReason.NONE
var _catch_source: CatchSource
var _is_resolving: bool = false
var _day_number: int
var _quota: int
var _bait_remaining: int
var _net: FishingNet


func _init(
	day_number: int,
	quota: int,
	bait_count: int,
	net_slots: int,
	weight_cap_kg: int,
	catch_source: CatchSource = null,
) -> void:
	assert(day_number > 0, "Day number must be positive.")
	assert(quota >= 0, "Daily quota cannot be negative.")
	assert(bait_count > 0, "Daily bait must be positive.")
	_catch_source = catch_source
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


func can_cast() -> bool:
	return (
		_catch_source != null
		and not _is_resolving
		and not is_finished()
		and _bait_remaining > 0
		and not _net.is_full()
		and not _net.is_busted()
	)


func cast() -> CastResult:
	if not can_cast():
		return CastResult.new(CastResult.Status.REJECTED)
	_is_resolving = true
	_bait_remaining -= 1
	var fish := _catch_source.draw()
	if fish != null and (not fish.is_valid() or not _net.add_fish(fish)):
		# A broken source must not turn an invalid fish into a paid empty catch.
		_bait_remaining += 1
		_is_resolving = false
		return CastResult.new(CastResult.Status.SOURCE_ERROR)
	_update_end_reason()
	_is_resolving = false
	var status := CastResult.Status.EMPTY if fish == null else CastResult.Status.CAUGHT
	return CastResult.new(status, fish)


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
	# Empty nets may return; neither returning twice nor returning mid-cast is valid.
	if _is_resolving or is_finished():
		return false
	_end_reason = EndReason.RETURNED
	return true
