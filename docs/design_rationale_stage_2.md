# Design rationale — Stage 2: a readable sea

## Requirement

Stage 1 playtesting showed that the core decision ("cast again, or return?") felt random. Players had no idea what was in the sea or how heavy the fish might be. One more cast at 10 kg and at 16 kg felt the same. Under Stage 1 odds, the chance of breaking the net rises by only about 2 percentage points per extra kilogram between 6 and 16 kg.

The group set the Stage 2 requirement from these playtests:

1. Each day has a **finite, visible sea**. The player can see how many of each fish type remain and each type's weight range.
2. The player can see the **next-cast odds**: break the net, land exactly 21 kg, no catch.
3. The rent is also shown in **kilograms**, so the player knows when the day is safe.
4. Stage 1 rules must not change: forced retention, 21 kg cap, settlement, rents and seven days.

## Design

| Decision | Alternatives considered | Why this one |
| --- | --- | --- |
| New `SeaPoolCatchSource` implementing the existing `CatchSource` | Add a pool inside `FishingDay` or `RandomCatchSource` | The Stage 1 extension point fits exactly. `FishingDay`, settlement and the net do not change (OCP). Any `CatchSource` remains substitutable (LSP) |
| Stock each day from the **same** distribution | Hand-designed daily seas | Players who ignore the report get Stage 1 odds. Only the decision quality changes, so the Stage 1 balance stays valid |
| Odds and counts as **optional queries** on `CatchSource` with `{}` defaults | A separate interface for observable sources | GDScript has no interfaces. Duck typing (`has_method`) would hide the contract. Defaults keep `FixedCatchSource` unchanged. The trade-off: every source now carries three small queries (an ISP cost we accept) |
| `CatchForecast` as a pure domain calculation | Compute percentages in the view | The odds are a game rule, testable headlessly with exact expected values. The view only formats them |
| `SeaReportPanel` presentation component | Add rendering code to `GameView` | Keeps `GameView` from growing into a god class (SRP). Its own script can be reused or replaced |
| Default source chosen in `GameSession._create_default_source()` | Factory object injected into the session | One small, documented branch is simpler than a factory with one caller. Tests already inject sources through `start_day(source)` |
| `sea_pool_size = 0` restores Stage 1 draws | Remove independent draws | Keeps Stage 1 behaviour reproducible for comparison and regression tests |

## Evidence the core stayed stable

- All 7 Stage 1 test suites (688 checks) run **unmodified** and pass on Stage 2. The new `test_sea` suite adds 43 checks.
- `FishingNet`, `Fish`, `CastResult`, `SettlementRules`, `DayResult`, `FishDefinition`, `GameController` and `FixedCatchSource` are byte-for-byte unchanged.
- See [change map](change_map_stage_1_to_2.md).

## Balance check

`tools/balance_sim.gd`, single day, income in kg-equivalent. Seed 2026; 50,000 days per row (`-- 50000 0,12`), the 8-outcome row 30,000 days (`-- 30000 8`):

| Sea | Strategy | Mean | Bust |
| --- | --- | ---: | ---: |
| Independent (Stage 1) | Stop at ≥ 14 kg | 13.66 | 14.1% |
| Independent (Stage 1) | Cast while break < 20% | 13.54 | 19.5% |
| 12 outcomes | Stop at ≥ 14 kg | 13.67 | 14.0% |
| 12 outcomes | Cast while break < 20% | 13.96 | 12.5% |
| 8 outcomes | Cast while break < 20% | 14.17 | 7.5% |

Ignoring the report gives Stage 1 results. Reading it lowers the bust rate. A smaller sea rewards reading it more strongly; 12 was chosen as a moderate default.

## Anticipated next steps

From the design workbook's open items: per-species value and rare fish (P04), a catalogue with first-catch rewards (P03), release of unwanted fish (P01), and a rent curve raised to match a richer economy (P02). Stage 2 keeps `Fish.species_id` and `FishDefinition` as the places these will attach.
