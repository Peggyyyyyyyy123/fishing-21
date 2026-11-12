# Fishing21

A small 2D fishing game built with Godot and GDScript for AP6412, Route A. Decide whether to cast again or return to shore: exceeding 21 kg breaks the net and loses the day's fish sales. Stage 2 makes the sea readable; Stage 3 makes every catch a choice: ten species with their own value, keep or release, and a field guide of discoveries. The current refinement build is a **three-day voyage**, with daily rents of **60, 180 and 280 gold**.

## Group and responsibility

Group: **Group5**.

| Member | GitHub | Personal branches | Main responsibility |
| --- | --- | --- | --- |
| Li Peiqi | `Peggyyyyyyyy123` | `LPQ/featrue-build`, `LPQ/featrue-stage1`, `LPQ/refinement` | Stage 1 implementation, tests and freeze; post-Stage 3 playtest refinements ([contribution record](evidence/LPQ/contribution.md)) |
| Chin Hsien Yeh | `Lecter1007` | `YCH/stage-2`, `YCH/stage-3` | Stage 2 and Stage 3 design and implementation, Class Maps and change maps |

## Project status

| Version | Tag | What it adds |
| --- | --- | --- |
| Stage 1 | [`stage-1`](https://github.com/Peggyyyyyyyy123/fishing-21/tree/stage-1) | Complete seven-day game: casting, forced retention, 21 kg rule, settlement, rent, failure, victory, restart. See [the freeze record](docs/stage_1_release.md) |
| Stage 2 | [`stage-2`](https://github.com/Peggyyyyyyyy123/fishing-21/tree/stage-2) | Finite visible daily sea, sea report, next-cast odds, rent in kilograms. See [Stage 2 rationale](docs/design_rationale_stage_2.md) |
| Stage 3 | [`stage-3`](https://github.com/Peggyyyyyyyy123/fishing-21/tree/stage-3) | Ten species with prices and rarity, keep or release, discovery rewards, field guide, rents 180–300, full-screen interface. See [Stage 3 rationale](docs/design_rationale_stage_3.md) |

Each tag preserves its independently runnable stage version. Earlier tags are never moved. The three-day balance and latest interface changes were developed on [`LPQ/refinement`](https://github.com/Peggyyyyyyyy123/fishing-21/tree/LPQ/refinement) and are now integrated into `main`. They are not included in the frozen tags.

## Requirements

- Tested on Windows with **Godot 4.7.2 stable .NET/Mono edition**, build `ed1daf0bf`.
- Implementation language: **GDScript** (`.gd`), including the gameplay model and UI. This project does not contain a C# build or project-specific NuGet dependencies.
- Renderer: **Compatibility**. Use a graphics driver supported by Godot's Compatibility renderer.
- Git is needed for cloning and version-history evidence. No third-party Godot add-ons or test framework installations are required.
- Optional, development only: Python 3 with NumPy to rerun `tools/balance_choices.py` (rent calibration). Running the game and tests needs only Godot.

Use the tested editor version for reproducible assessment. Other Godot versions and platforms have not been verified.

## Get the project and run

Clone the repository and check out the current three-day refinement build:

```powershell
git clone https://github.com/Peggyyyyyyyy123/fishing-21.git
cd fishing-21
git checkout main
```

To run a frozen assessment stage instead, use `git checkout stage-1`, `git checkout stage-2` or `git checkout stage-3`. Those versions retain their original rules and seven-day voyages. Private repositories require an authorised GitHub account.

1. Open the Godot Project Manager and choose **Import**.
2. Select this folder's `project.godot`, then open the project.
3. Allow the initial resource import to finish.
4. Press **F5**, or click **Run Project**. The configured main scene is `scenes/main.tscn`.
5. Click **Start your 3-day voyage** to play.

No export or separate compilation step is needed to run this GDScript project in the editor. Godot regenerates its `.godot` cache locally; the cache is intentionally excluded from Git.

If Godot reports that project files changed externally, choose **Reload from disk** to use the current repository files. An empty editor tab does not require creating a new scene; use F5 to run the configured project.

### Command line on Windows

Run from the project root. Replace the executable path below if Godot is installed elsewhere. The `_console.exe` executable exposes test output in the terminal.

```powershell
$godot = 'D:\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64_console.exe'
& $godot --editor --path . --import
& $godot --path .
```

For a fresh test-only import without the editor window, use `--headless --editor --path . --import` as shown below.

## Controls

| Button | Action |
| --- | --- |
| Start your 3-day voyage | Start a new run on Day 1. The displayed day count follows the configuration. |
| Cast · Bait n / 6 | Spend one bait and draw a catch. Input is temporarily locked during the casting animation. |
| Keep / Release (catch card) | Put the fish in the net, or let it go. The bait stays spent either way. An overweight catch is labelled on Keep, and Release has focus. |
| Return · Pay rent | End the current day voluntarily and display settlement. Grey remains clickable and shows the rent shortfall, with a border and hover feedback; gold means today's income covers rent. Not available while a catch card is open or casting is in progress. |
| Today's Sea | Hover or focus to see the sea report. |
| Field Guide | Open the collection from the game or the result screen. The opening menu has no Field Guide button. Esc closes it. |
| Continue · Next day | After a passing non-final day, start the next day with a fresh net and bait. |
| Start a new voyage | From the result screen, reset the run to Day 1 with zero savings. The field guide starts empty again. |
| F11 / Esc | Toggle fullscreen / leave fullscreen. The game starts fullscreen. |

Use the mouse for the primary interaction. The game requires no movement controls.

The Stage 1 and Stage 2 sections below describe the frozen historical versions. The Stage 3 section describes the extended mechanics and distinguishes the original tag from the current refinement build. In the current build, the top-right coin display **Today** means today's income before rent, not accumulated savings. Cover each day's rent to continue; passing Day 3 wins. Savings still cannot cover a daily shortfall.

## Stage 1 rules

| Rule | Default value or behaviour |
| --- | --- |
| Run length | 7 days |
| Bait | 6 per day. Every cast uses one, including a cast with no catch. |
| Net slots | 5 fish |
| Weight limit | 21 kg. Only **greater than** 21 kg breaks the net. |
| Catch retention | Every caught fish must enter the net. No releasing or discarding. |
| Normal daily income | Total weight × 10 gold/kg |
| Perfect catch | Exactly 21 kg at settlement pays ×2, giving 420 gold. |
| Bust | Day ends immediately with 0 income. |
| Other automatic endings | Full net or exhausted bait. Bust takes priority when conditions coincide. |
| Voluntary ending | Return at any time between casts, including with an empty net. |
| Daily rent | 40, 50, 60, 70, 80, 90 and 100 gold on Days 1–7 |
| Passing a day | Daily income must be at least that day's rent. Savings cannot cover a shortfall. |
| Savings | Add income minus rent only after passing. |
| Failure / victory | Fail on any unpaid day. Win by passing Day 7. |

Exactly 21 kg does not itself force a return. If bait and slots remain, casting again is allowed and can cause a bust.

### Catch distribution

| Outcome | Probability | Integer weight |
| --- | ---: | ---: |
| No catch | 20% | 0 kg, no net slot used |
| Small fish | 55% | 1–4 kg |
| Medium fish | 15% | 5–10 kg |
| Large fish | 8% | 11–16 kg |
| Huge fish | 2% | 17–21 kg |

The source selects an outcome by probability, then chooses a weight uniformly within that outcome's inclusive integer range. Each checked-out version stores its own numeric defaults and display names in `config/default_game_config.tres`; the current file contains the ten-species configuration, not this historical Stage 1 table.

## Stage 2 rules: a readable sea

All Stage 1 rules above still apply. Stage 2 adds information, not new ways to earn:

- Each morning the sea is stocked with `sea_pool_size` outcomes (default **12**), each drawn from the distribution above. Empty casts are part of the pool.
- The **sea report** lists each outcome with its weight range and `remaining / stocked` count. Every cast removes one outcome, so what has been caught changes the next cast's odds.
- Exact weights stay hidden: a fish's weight is rolled within its range when it is caught.
- **Next-cast odds** show the chance to break the net, to land exactly 21 kg, and of no catch, plus the room left. The weight bar turns amber at ≥15% break chance and red at ≥35%.
- The rent is shown in kilograms (`rent ÷ price`, rounded up). The net header shows *rent covered* once it is reached.

`sea_pool_size = 0` restores Stage 1 independent draws. Balance comparison: [Stage 2 rationale](docs/design_rationale_stage_2.md#balance-check).

## Stage 3 rules: every catch is a choice

- **Ten species** replace the five size classes, each with its own rarity, weight range, price per kg and first-discovery reward ([table](docs/catch_choices.md#fish-configuration)). Every cast catches a fish.
- After each catch a card shows the fish's weight, rarity and sale value. **Keep** puts it in the net; **Release** lets it go. Either way the bait is spent and the fish leaves today's sea.
- Daily income = sale value of the net (species price × kg), **×2 at exactly 21 kg**, plus **discovery rewards** for species caught for the first time. On a bust the sale value is lost but discovery rewards are kept. Discovery rewards are never doubled.
- The **field guide** records every species caught in the current voyage (kept or released), its catch count and biggest weight. Starting a new voyage empties it, so discovery rewards are available again in every voyage. It is not saved to disk. (Changed after `stage-3`; see [post-Stage 3 fixes](docs/post_stage_3_fixes.md).)
- **Current refinement build:** 3 days, with rents of **60, 180 and 280 gold**. Passing Day 3 wins; there is no Day 4. Only rent and run length were changed for difficulty; fish probabilities, weights, prices, discovery rewards, bait, slots and the 21 kg rule are unchanged. Run length follows the quota list in `GameConfig`, and menu/day labels follow that configuration.
- **Frozen `stage-3` tag:** retains the original seven-day rents of 180, 210, 240, 250, 260, 280 and 300 gold.
- The sea report opens on hover over *Today's Sea*. The next-cast percentages from Stage 2 are no longer shown.

## Code structure and design

```text
config/         GameConfig and FishDefinition resources
domain/         Catch generation, sea pool, odds, net, day, catalogue, settlement and run rules
presentation/   GameController, GameView and its components (SeaReportPanel, CatchCard,
                FieldGuideBook, FishArt, UiKit), FishingView
scenes/         Main scene and interface scene
tests/          Headless rule tests, actual-scene UI tests and test helpers
tools/          Dev helpers: balance simulation and screenshot capture
docs/           Class Maps, design rationale, change maps, acceptance records
docs/design/    Numeric design workbook (fishing21_config_v0.1.xlsx)
evidence/       Per-student AI logs and contribution records
project.godot   Editor settings and main-scene entry point
```

Design documents:

| Version | Class Map | Design rationale | Change map |
| --- | --- | --- | --- |
| Stage 1 | [class_map_stage_1](docs/class_map_stage_1.md) | [design_rationale_stage_1](docs/design_rationale_stage_1.md) | — |
| Stage 2 | [class_map_stage_2](docs/class_map_stage_2.md) | [design_rationale_stage_2](docs/design_rationale_stage_2.md) | [Stage 1 → 2](docs/change_map_stage_1_to_2.md) |
| Stage 3 | [class_map_stage_3](docs/class_map_stage_3.md) | [design_rationale_stage_3](docs/design_rationale_stage_3.md) | [Stage 2 → 3](docs/change_map_stage_2_to_3.md) |
| After Stage 3 | [class-map update](docs/post_stage_3_fixes.md#final-class-map) | [post-Stage 3 fixes](docs/post_stage_3_fixes.md) | Stage 3 → post-stage fixes on `main` |

The post-stage document records the earlier catalogue reset and header fixes. Later three-day balance and interface refinements are summarised in this README; the older document still contains historical seven-day wording. The refinements add no production classes.

`GameSession` owns progression, coin payment and the `FishCatalog`. `FishingDay` owns casting, bait, the catch waiting for keep/release, today's discoveries and the daily end conditions. `FishingNet` stores catches. `SettlementRules` owns every money rule (species price, perfect multiplier, bust income, discovery rewards) and calculates a `DayResult` or a preview without paying coins itself. State guards prevent duplicate settlements and skipped days.

`FishingDay` receives the small abstract `CatchSource` contract. `SeaPoolCatchSource` supplies normal gameplay (a finite daily sea). `RandomCatchSource` supplies independent draws when `sea_pool_size` is 0, and test-only `FixedCatchSource` supplies reproducible outcomes. `CatchForecast` computes next-cast odds from public information; since Stage 3 it is used by the balance tool, not the interface. Fish species differ through `FishDefinition` data rather than subclasses without different behaviour.

`GameController` connects input to the model. `GameView` displays state and results and composes `SeaReportPanel`, `CatchCard` and `FieldGuideBook`. `FishingView` draws the scenery. Domain code has no dependency on scene nodes or buttons, although it uses Godot types such as `RefCounted` and `Resource`.

## Verification

From the project root, use the console executable defined above:

```powershell
& $godot --headless --editor --path . --import
if ($LASTEXITCODE -ne 0) { throw 'Godot import failed.' }

$testSuites = @(
    'foundation', 'initialization', 'casting',
    'settlement', 'progression', 'ui', 'review', 'sea',
    'choices', 'interface'
)
foreach ($suite in $testSuites) {
    & $godot --headless --path . --script "res://tests/test_$suite.gd"
    if ($LASTEXITCODE -ne 0) { throw "Failed test suite: $suite" }
}
```

Recorded on **2026-11-12** for source commit **`cf84b44`** on `LPQ/refinement`: **10 suites, 1525 checks, 0 failures**. Legacy scenarios replay Stage 1 forced retention using `KeepEveryCatch` and `LegacyTestConfig`. Production configuration and three-day progression are also checked, including the absence of a fourth day and restart after victory.

| Suite | Checks | Failures |
| --- | ---: | ---: |
| Foundation | 51 | 0 |
| Initialization | 44 | 0 |
| Casting | 54 | 0 |
| Settlement | 50 | 0 |
| Progression | 427 | 0 |
| UI | 39 | 0 |
| Review regressions | 13 | 0 |
| Sea report (Stage 2) | 41 | 0 |
| Catch choices and catalogue (Stage 3) | 670 | 0 |
| Interface (Stage 3) | 136 | 0 |
| **Total** | **1525** | **0** |

These results cover the recorded source version and do not guarantee untested changes or environments. Tests include probability boundaries, 21/22 kg limits, keep/release, discovery rewards, per-voyage catalogue reset, ending priority, repeated input, settlement idempotence, the current three-day voyage, legacy seven-day progression, failure with savings and restart.

`test_ui.gd` instantiates the production scene, uses a fixed catch source, and triggers actual button-signal connections to reproduce victory, bust and restart. It runs headlessly and does not replace mouse/keyboard or visual checks. `test_progression.gd` includes a mixed seven-day scenario with expected final savings of **520 gold** (Stage 1 economy).

See [the acceptance checklist](docs/stage_1_acceptance.md) for observed manual Stage 1 results and outstanding items.

## Known limitations

- Basic native 2D scenery and casting animation, with no audio and no save/load.
- With ten species, the hover sea report is tall and can overlap the header on short screens.
- The old seven-day calibration in `tools/balance_choices.py` and the Stage 3 design notes describes the original balance. Its victory-rate estimate does not describe the current three-day build; no verified player win rate is claimed for the new rents.
- Shops and upgrades are not implemented.
- Only Windows with the tested Godot version has been verified.
- Some manual acceptance items remain open, including a complete live three-day demonstration, keyboard navigation and separate checks of the frozen stage versions.
- Godot's embedded game preview may display at 1.0× with surrounding margins. This is separate from resizing the standalone game window.

## GitHub and assessment evidence

- [Repository](https://github.com/Peggyyyyyyyy123/fishing-21)
- Integrated refinement branch: [LPQ/refinement](https://github.com/Peggyyyyyyyy123/fishing-21/tree/LPQ/refinement) · [main → refinement comparison](https://github.com/Peggyyyyyyyy123/fishing-21/compare/main...LPQ/refinement)
- Personal branches: [LPQ/featrue-build](https://github.com/Peggyyyyyyyy123/fishing-21/tree/LPQ/featrue-build), [LPQ/featrue-stage1](https://github.com/Peggyyyyyyyy123/fishing-21/tree/LPQ/featrue-stage1), [YCH/stage-2](https://github.com/Peggyyyyyyyy123/fishing-21/tree/YCH/stage-2), [YCH/stage-3](https://github.com/Peggyyyyyyyy123/fishing-21/tree/YCH/stage-3) (the `featrue` spelling matches the repository)
- [Pull requests (open and closed)](https://github.com/Peggyyyyyyyy123/fishing-21/pulls?q=is%3Apr) · [Merge history on main](https://github.com/Peggyyyyyyyy123/fishing-21/commits/main)
- Tags: [`stage-1`](https://github.com/Peggyyyyyyyy123/fishing-21/tree/stage-1), [`stage-2`](https://github.com/Peggyyyyyyyy123/fishing-21/tree/stage-2), [`stage-3`](https://github.com/Peggyyyyyyyy123/fishing-21/tree/stage-3) · [all tags](https://github.com/Peggyyyyyyyy123/fishing-21/tags)
- Comparisons: [`stage-1...stage-2`](https://github.com/Peggyyyyyyyy123/fishing-21/compare/stage-1...stage-2), [`stage-2...stage-3`](https://github.com/Peggyyyyyyyy123/fishing-21/compare/stage-2...stage-3)

Stage 1 was merged into `main` with a merge commit (`2b87092`). Stages 2 and 3 are integrated from `YCH/stage-2` and `YCH/stage-3` through pull requests with merge commits, then tagged on `main`.

AI communication logs:

| Member | Location |
| --- | --- |
| Li Peiqi | [evidence/LPQ](evidence/LPQ/README.md) |
| Chin Hsien Yeh | `evidence/YCH/` (to be added by the student) |

Still to complete before submission: retain the completed manual acceptance evidence, append Li Peiqi's later AI conversations beyond the existing 2026-11-07 export, add Chin Hsien Yeh's complete AI logs (or a no-AI declaration where applicable), and prepare the final group report, signed declarations and submission ZIP. Include evidence that the lecturer's later requirements were received only after the preceding stage was frozen.

## Development notes

- [Foundation](docs/stage_1_foundation.md)
- [Initialization](docs/stage_1_initialization.md)
- [Casting](docs/stage_1_casting.md)
- [Settlement](docs/stage_1_settlement.md)
- [Progression](docs/stage_1_progression.md)
- [Interface](docs/stage_1_ui.md)

These notes describe successive Stage 1 implementation steps. Stages 2 and 3 are documented in the design table above; Stage 3 balance and interface notes: [catch choices](docs/catch_choices.md), [interface redesign](docs/interface_redesign.md).

## Personal evidence index

[LPQ AI dialogue, contributions and review cases](evidence/LPQ/README.md) contains Li Peiqi's chronological message export, screenshot attachments, commit inventory and integration status for Stage 1.
