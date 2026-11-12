# Change map — Stage 2 → Stage 3

Compare view: [`stage-2...stage-3`](https://github.com/Peggyyyyyyyy123/fishing-21/compare/stage-2...stage-3)

## Summary

| Area | Files | Lines added / removed |
| --- | ---: | ---: |
| Domain rules (`domain/`) | 5 (1 new) | +218 / −35 |
| Persistence (`persistence/`) | 1 new | +47 / 0 |
| Configuration (`config/`) | 3 | +105 / −28 |
| Presentation (`presentation/`, `scenes/`, `project.godot`) | 9 (4 new) | +787 / −435 |
| Tests (`tests/`) | 12 (4 new) | +366 / −55 |
| Tools | 5 (3 new) | +179 / −1 |

The large presentation numbers are the new full-screen interface, which moved the layout from `game_view.tscn` into code-built components.

## Added

| File / class | Layer | Why it was needed |
| --- | --- | --- |
| `FishCatalog` | Domain | Discoveries and catch records across voyages, with legacy-save migration |
| `FishCatalogStore` (`persistence/`) | Persistence | Saves the catalogue atomically. Existed in the local prototype under `domain/`; moved because it is I/O |
| `CatchCard` | Presentation | Keep-or-release card |
| `FieldGuideBook` | Presentation | Two-page field guide |
| `FishArt` | Presentation | Pixel fish drawn in code, shared by card and book |
| `UiKit` | Presentation | Static layout helpers and theme for all components |
| `KeepEveryCatch`, `LegacyTestConfig` | Test helpers | Run Stage 1 assertions under Stage 3 rules |
| `test_choices`, `test_interface` | Tests | Keep/release, rewards, catalogue, persistence, UI |
| `balance_choices.py`, `capture_choices.gd`, `capture_interface.gd` | Tools | Rent calibration and screenshots |

## Modified

| File / class | Change | Why | Local? |
| --- | --- | --- | --- |
| `FishDefinition` | + `rarity`, `price_per_kg` (0 = base), `discovery_reward` | Species economy is data | Yes |
| `GameConfig` + `.tres` | Ten species, rents 180–300; `price_per_kg` is now the base price | New content and balance | Data only |
| `FishingDay` | + pending catch, `resolve_catch()`, discoveries; cast no longer adds to the net directly | Keep-or-release rule | Ending order, bait and net rules unchanged |
| `SettlementRules` | Species prices, discovery rewards, `preview_income()`; constructor takes the definitions | All money rules in one class | Bust/perfect logic unchanged in meaning |
| `DayResult` | + discovery income | Result screen shows it | Yes |
| `GameSession` | Owns `FishCatalog`; `preview_income()`, `get_fish_value()`; removed `get_next_cast_forecast()` | Catalogue spans voyages; UI no longer shows odds | State machine unchanged |
| `GameController` | Loads/saves the catalogue; forwards keep/release | Persistence and new input | Yes |
| `GameView`, `game_view.tscn`, `project.godot` | Full-screen layout composed of components | Interface redesign | Presentation only |
| `SeaReportPanel` | Hover report; next-cast text removed | Interface redesign | Presentation only |
| Stage 1 suites | `day.cast()` → `KeepEveryCatch.cast(day)`; `LegacyTestConfig`; `SettlementRules` constructor gains the species list | Stage 1 = Stage 3 with a keep-all player | Assertions unchanged |
| `test_foundation`, `test_initialization` | Expected production values | New fish list and rents | Data checks only |
| `test_sea` | Legacy fixture; session forecast checks replaced; UI checks for the hover report | Removed session forecast API and new UI | — |

## Deleted

| Item | Why |
| --- | --- |
| `GameSession.get_next_cast_forecast()` | No caller after the interface stopped showing next-cast odds. `CatchForecast` itself stays for the balance tool |
| Scene-built HUD nodes in `game_view.tscn` | Replaced by code-built components |

## Unchanged

`Fish`, `FishingNet`, `CastResult`, `CatchSource`, `RandomCatchSource`, `SeaPoolCatchSource`, `CatchForecast`, `FishingView`, `FixedCatchSource`, `scenes/main.tscn`.

## What the evidence shows

Two Stage 1 boundaries paid off. `SettlementRules` was already the only place that turned a day into money, so species prices and discovery rewards were added there instead of spreading through the code. The `CatchSource` family did not change at all. The main cost was `FishingDay`: forced retention was a rule inside `cast()`, so introducing a choice changed that method. The new pending-catch step is local to the day, and the Stage 1 behaviour is still reproducible by always choosing "keep".
