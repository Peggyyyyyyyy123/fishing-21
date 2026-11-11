# Design rationale — Stage 3: every catch is a choice

## Requirement

Playtesting Stage 2 showed that, once the sea was readable, every fish was worth the same per kilogram, so the only decision left was "how close to 21 kg". The group set the Stage 3 requirement from the design workbook's open items (P01 release, P03 catalogue, P04 per-species price, P02 rent curve):

1. **Ten species** with their own rarity, weight range and price per kg.
2. **Keep or release** each catch. Releasing spends the bait but not a slot or weight. Released fish do not return to the sea.
3. **First discovery** of a species pays a one-time reward, kept even on a bust and never doubled by the perfect catch.
4. A **field guide** that persists between voyages and records catch count and biggest weight.
5. **Rents raised to 180–300 gold** to fit the richer economy.
6. A full-screen interface: catch card, field guide book, sea report on hover.

The Stage 1 core stays: bait, net slots, the 21 kg bust rule, exactly-21 doubling of fish sales, daily rent, seven days.

## Design decisions

| Decision | Alternatives considered | Why this one |
| --- | --- | --- |
| `FishCatalog` domain class owns discoveries and records | A raw `Dictionary` shared between session and day | Encapsulation: only `record_catch()` can change it; legacy-save migration lives in one place. The day receives the catalogue (uses-a) instead of mutating a shared dictionary |
| `FishingDay` records **which** species were discovered; `SettlementRules` decides **what they pay** | The day adds discovery gold itself | SRP: casting rules and money rules change for different reasons. A future reward change touches `SettlementRules` only |
| `SettlementRules.preview_income()` and `calculate()` share one private `_income()` | A separate preview formula in the day or UI | One rule, one place. The header "Earned" and the settlement result cannot disagree |
| Species price overrides the base price; `price_per_kg = 0` means "use base" | Only species prices; or a silent hard-coded fallback | Stage 1/2 configurations and tests keep working unchanged (OCP via data). The rule is explicit and in one method |
| Pending catch inside `FishingDay` with `resolve_catch(keep)` | Keep/release handled by the controller | The day already owns bait, net and ending order; it guarantees "no cast or return while choosing" |
| Empty outcomes still valid (`CastResult.EMPTY`) | Treat empty as an error | The production fish list has no empty outcome, but Stage 1 configurations still run. Behaviour is data-driven |
| `_is_resolving` kept | Remove it as unused | It rejects re-entrant casts from inside a source's `draw()`; covered by `test_casting` |
| `FishCatalogStore` moved to `persistence/` | Keep it in `domain/` | File access is infrastructure. The store moves plain dictionaries; `FishCatalog` interprets them |
| `GameView` split into `SeaReportPanel`, `CatchCard`, `FieldGuideBook`; helpers in static `UiKit` | One 500-line view inheriting a helper base class | Each component has one reason to change. Static helpers avoid an "is-a" relationship that only shared code |
| `GameSession.get_next_cast_forecast()` removed | Keep it unused | The redesigned interface no longer shows next-cast sentences. `CatchForecast` stays because the balance tool uses it for strategy comparisons |

## Evidence the core stayed stable

- `Fish`, `FishingNet`, `CastResult`, `CatchSource`, `RandomCatchSource`, `SeaPoolCatchSource`, `CatchForecast` and `FishingView` are unchanged.
- Stage 1 suites keep their assertions. Forced retention is Stage 3 played by a player who keeps every catch, so they call `KeepEveryCatch.cast(day)` instead of `day.cast()`, and they use `LegacyTestConfig` for Stage 1 numbers. Only the two suites that check the production configuration values (foundation, initialization) changed their expected numbers.
- See the [change map](change_map_stage_2_to_3.md).

## Balance

Rents were calibrated with `tools/balance_choices.py` (Python 3 + NumPy, development only) for a conditional Day 3 pass rate around 50%. Details: [catch choices](catch_choices.md). The cumulative seven-day victory rate in that model is low (under 1%). The model ignores future discovery rewards, so it underestimates good players. Real playtests are still needed before the final submission.

## Known limitations

- The hover sea report is tall with ten species and can overlap the header on short screens.
- Discovery rewards are once per save file; restarting a voyage does not reset them.
