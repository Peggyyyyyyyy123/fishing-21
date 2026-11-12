# Catch choices and catalogue — 2026-11-11

## Fish configuration

| Species | Rarity | Base share | Integer kg | Gold/kg | First discovery |
| --- | --- | ---: | --- | ---: | ---: |
| Sardine | Common | 20% | 1–3 | 10 | 3 |
| Mackerel | Common | 18% | 2–4 | 10 | 3 |
| Horse Mackerel | Common | 16% | 3–5 | 10 | 3 |
| Mullet | Common | 12% | 4–6 | 10 | 3 |
| Sea Bass | Uncommon | 10% | 6–9 | 12 | 6 |
| Red Seabream | Uncommon | 8% | 8–11 | 12 | 6 |
| Golden Butterflyfish | Rare | 6% | 2–4 | 16 | 12 |
| Grouper | Rare | 5% | 11–15 | 16 | 12 |
| Moon Angelfish | Epic | 3% | 5–8 | 20 | 20 |
| Golden Tuna | Legendary | 2% | 17–21 | 20 | 30 |

Shares stock the daily 12-fish sea. Actual next-cast probabilities depend on remaining counts. Each species rolls uniformly over its inclusive integer weight range. The total discovery budget is 98 gold.

## Settlement and persistence

`income = sale_value * (2 if weight == 21 else 1) + daily_discovery_rewards`.
On a bust, fish-sale value is replaced by zero; discovery rewards remain. Daily rewards reset each morning. Discovery identity does not reset when restarting a voyage. The catalogue is registered and saved when the catch is drawn, before choosing keep or release. It is not a save of the active voyage.

The catch card must be resolved before another cast, return, or settlement. Last-bait release ends the day; last-bait retention includes that fish. Releasing spends the bait but no slot/weight. Caught fish never return to the pool. Keeping an overweight catch remains possible with an explicit warning and release focused by default.

## Balance calibration

The design target is a **conditional Day 3 pass rate around 50% among players reaching Day 3**, not a 50% cumulative survival rate from the beginning. Rents are 180/210/240/250/260/280/300.

Reproduce with Python 3 and NumPy: `python tools/balance_choices.py`. This reads the actual `.tres` configuration. NumPy is a development-only dependency; running the game requires no Python packages.

Seed 2112, 30,000 new-save voyages, failure ends a voyage:

| Day | Rent | Conditional pass | Cumulative pass |
| --- | ---: | ---: | ---: |
| 1 | 180 | 92.96% | 92.96% |
| 2 | 210 | 76.05% | 70.70% |
| 3 | 240 | 51.56% | 36.45% |
| 4 | 250 | 46.48% | 16.94% |
| 5 | 260 | 42.81% | 7.25% |
| 6 | 280 | 35.66% | 2.59% |
| 7 | 300 | 33.12% | 0.86% |

Policy: dynamic programming maximizes pass probability without future discovery income. On each observed catch, already earned rewards reduce the remaining target, rounded upward to a five-gold grid. Stop when rent is covered. Future first-discovery rewards and public sea composition are not used by the policy; it is not an optimal policy for the full game. Ignoring the sea report makes independent observed draws equivalent to uniformly drawing from an independently stocked 12-fish pool. There are no day-specific stocking restrictions.

For a completely discovered catalogue, the independent-draw optimal Day 3 baseline is 45.45%. These are reproducible model results, not human win rates. Tune after playtests, separating new-save and complete-catalogue players. Strictly declining conditional rates across seven days imply a low final victory rate under failure-means-restart rules.

## Validation

Ten Godot test suites (1,535 checks) cover configuration, lifecycle, casting, settlement, progression, production UI signals, sea counts, catch decisions and catalogue persistence. `LegacyTestConfig` provides the Stage 1 fish and rents, and `KeepEveryCatch` replays Stage 1 forced retention, so earlier assertions still run; test_foundation and test_choices validate the current production configuration. UI tests use isolated `res://tests/` catalogue files and do not touch the player's catalogue.

## Interface revision

See [interface redesign](interface_redesign.md). Runtime text and species names are now English. Catalogue records retain biggest weight and caught counts, with migration from historical boolean unlocks. Fish distributions, prices, discovery rewards and all rents remain unchanged.
