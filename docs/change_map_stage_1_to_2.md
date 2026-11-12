# Change map — Stage 1 → Stage 2

Compare view: [`stage-1...stage-2`](https://github.com/Peggyyyyyyyy123/fishing-21/compare/stage-1...stage-2)

## Summary

| Area | Files | Lines added / removed |
| --- | ---: | ---: |
| Domain rules (`domain/`) | 6 (2 new) | +203 / −1 |
| Configuration (`config/`) | 2 | +5 / 0 |
| Presentation (`presentation/`, `scenes/`) | 4 (1 new) | +140 / −4 |
| Tests (`tests/`) | 1 new | +159 / 0 |
| Tools, docs, evidence settings | new | — |

Stage 1 tests: 7 suites, **688 checks, unmodified, all passing**.

## Added

| File / class | Layer | Why it was needed |
| --- | --- | --- |
| `domain/sea_pool_catch_source.gd` · `SeaPoolCatchSource` | Domain | Finite daily sea drawn without replacement: the core of the requirement. Implements the existing `CatchSource` |
| `domain/catch_forecast.gd` · `CatchForecast` | Domain | Next-cast odds are a rule calculation and must be testable without the UI |
| `presentation/sea_report_panel.gd` · `SeaReportPanel` | Presentation | Owns the new report UI so `GameView` does not take on another responsibility |
| `tests/test_sea.gd` | Test | Stocking, without-replacement draws, exact odds, session integration and report UI (43 checks) |
| `tools/balance_sim.gd`, `tools/capture_screens.gd` | Dev tools | Balance comparison and reproducible screenshots |
| `docs/class_map_stage_*.md`, `docs/design_rationale_stage_*.md`, this file, `docs/design/fishing21_config_v0.1.xlsx` | Docs | Required design evidence |
| `evidence/.gdignore` | Project settings | Stops Godot importing evidence files as game resources |

## Modified

| File / class | Change | Why | Local? |
| --- | --- | --- | --- |
| `CatchSource` | +3 query methods with `{}` defaults | The UI needs odds and counts. Defaults keep other sources unchanged | Yes: `FixedCatchSource` untouched |
| `RandomCatchSource` | +`get_next_draw_chances()` | Odds still work with Stage 1 independent draws | Yes |
| `FishingDay` | +3 pass-through getters | Presentation must not reach into the source directly | Yes: `cast()` and ending rules untouched |
| `GameSession` | +`get_next_cast_forecast()`, default source in `_create_default_source()` | Single place that selects the concrete source; odds only while a cast is possible | Yes: state machine untouched |
| `GameConfig` + `default_game_config.tres` | +`sea_pool_size` (12) and validation | Size of the daily sea; 0 restores Stage 1 | Yes |
| `GameView` + `game_view.tscn` | Sea panel node, rent in kg, weight-bar tint | Display of the new information | Presentation only |
| `FishingView` | Sun moved left | The new panel covered it | Presentation only |
| `README.md` | Stage 2 rules and tests | Documentation | — |

## Deleted

None.

## Unchanged

`Fish`, `FishingNet`, `CastResult`, `SettlementRules`, `DayResult`, `FishDefinition`, `GameController`, `FixedCatchSource`, `scenes/main.tscn`, and all seven Stage 1 test files.

## What the evidence shows

The Stage 1 `CatchSource` abstraction was the right extension point. The new behaviour arrived as a new implementation plus read-only queries. The rules that decide income, busting and progression did not change. Most other edits are presentation, which is where a new on-screen feature is expected to land.
