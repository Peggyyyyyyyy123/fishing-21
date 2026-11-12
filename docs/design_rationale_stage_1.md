# Design rationale — Stage 1

Written on the Stage 2 branch because the `stage-1` tag is frozen. It describes the decisions already in the Stage 1 code and in the step notes `docs/stage_1_*.md`. The numeric design workbook [`design/fishing21_config_v0.1.xlsx`](design/fishing21_config_v0.1.xlsx) predates the freeze. Its file date is 2026-11-03, while the freeze happened on 2026-11-07. It was added to Git later, so the repository cannot prove that date.

## Game model boundaries

- **Inside the model:** casting, bait, net capacity, the 21 kg rule, settlement, daily rent, the seven-day run, and win/lose states.
- **Outside the model:** buttons, layout, animation, scenery and timing. They live in `presentation/` and scenes.
- **Data, not code:** every number and every fish outcome is in `GameConfig` / `FishDefinition` resources.

## Key decisions

| Decision | Why | Principle / trade-off |
| --- | --- | --- |
| Fish sizes are `FishDefinition` data, not subclasses | Sizes differ only in numbers, not behaviour | OCP for new fish types; avoids an inheritance tree with no behaviour |
| `CatchSource` abstract class with `RandomCatchSource` and test-only `FixedCatchSource` | Tests and demos need reproducible catches. Gameplay needs randomness | DIP: `FishingDay` depends on the abstraction. LSP: both implementations honour the `draw()` contract |
| `FishingNet` separate from `FishingDay` | Storing catches and the day's bait and ending rules change for different reasons | SRP |
| `SettlementRules` computes but does not pay. `GameSession` pays | Pricing rules and run progression change independently. Paying only once is easier to guarantee in one place | SRP; idempotent `settle_day()` |
| `GameSession` state machine with guards | Prevents double settlement, skipped days and restart during casting | Robust handling of invalid actions |
| Domain has no scene-node dependency | Rules are testable headlessly. The view can be replaced | Separation of concerns |
| No interfaces added only for SOLID | Only `CatchSource` had two real implementations | Avoids checklist-driven patterns |

## Anticipated future needs

These come from the design workbook's open items (P01–P07) and from playing the game:

1. **Per-species pricing and rare fish** (workbook P04). Price is already separated in `SettlementRules`, and fish identity is kept in `Fish.species_id`.
2. **A catalogue / collection** (P03). Fish keep their species id, so a later collection can record them without changing the net.
3. **Different catch generation** (bait quality in P01). New `CatchSource` implementations can plug in.
4. **Rent curve changes** (P02, P07). Rents are a config list, and the run length follows that list.
5. **Releasing fish** (P01: "release item"). Retention is enforced in `FishingDay`, which is the one place to change.

## Known Stage 1 limitations

Players cannot see what is in the sea, so "one more cast?" is mostly a guess. This became the Stage 2 requirement.
