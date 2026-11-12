@abstract
class_name CatchSource
extends RefCounted
## Returns a valid, positive-weight fish, or null for an empty catch.

@abstract func draw() -> Fish


## Chance of each outcome on the next draw (species_id -> probability).
## An empty dictionary means the odds are not known to the player.
func get_next_draw_chances() -> Dictionary:
	return {}


## Stocked outcome counts for a finite sea; empty for sources without a pool.
func get_initial_counts() -> Dictionary:
	return {}


## Outcome counts still in a finite sea; empty for sources without a pool.
func get_remaining_counts() -> Dictionary:
	return {}
