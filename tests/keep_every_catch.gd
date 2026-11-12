class_name KeepEveryCatch
extends RefCounted
## Test helper: a player who keeps every catch. Stage 1 forced retention is exactly
## Stage 3 rules played this way, so Stage 1 tests use it instead of day.cast().


static func cast(day: FishingDay) -> CastResult:
	var result := day.cast()
	if result.get_status() == CastResult.Status.CAUGHT:
		day.resolve_catch(true)
	return result
