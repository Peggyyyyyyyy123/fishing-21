# Fishing21

A small 2D fishing game built with Godot and GDScript for AP6412, Route A. Decide whether to cast again or return to shore: every fish must stay in the net, and exceeding 21 kg loses the day's income.

## Project status

Stage 1 implements a complete seven-day game with an English interface, daily settlement, failure, victory and restart. It remains a development baseline: the `stage-1` release tag has **not** been created. Remaining manual acceptance and submission evidence must be completed before freezing it.

Stage 2 and Stage 3 requirements will be released by the lecturer after the preceding version is frozen. They are not implemented or assigned in advance.

## Requirements

- Tested on Windows with **Godot 4.7.2 stable .NET/Mono edition**, build `ed1daf0bf`.
- Implementation language: **GDScript** (`.gd`), including the gameplay model and UI. This project does not contain a C# build or project-specific NuGet dependencies.
- Renderer: **Compatibility**. Use a graphics driver supported by Godot's Compatibility renderer.
- Git is needed for cloning and version-history evidence. No third-party Godot add-ons or test framework installations are required.

Use the tested editor version for reproducible assessment. Other Godot versions and platforms have not been verified.

## Get the project and run

Clone the current personal development branch:

```powershell
git clone --branch LPQ/featrue-stage1 https://github.com/Peggyyyyyyyy123/fishing-21.git
cd fishing-21
```

This is a private repository, so access requires an authorised GitHub account.

1. Open the Godot Project Manager and choose **Import**.
2. Select this folder's `project.godot`, then open the project.
3. Allow the initial resource import to finish.
4. Press **F5**, or click **Run Project**. The configured main scene is `scenes/main.tscn`.
5. Click **Start your 7-day voyage** to play.

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
| Start your 7-day voyage | Start a new run on Day 1. The displayed day count follows the configuration. |
| Cast · Use 1 bait | Spend one bait and draw a catch. Input is temporarily locked during the casting animation. |
| Return · Settle the day | End the current day voluntarily and display settlement. |
| Continue · Next day | After a passing non-final day, start the next day with a fresh net and bait. |
| Restart / Start a new voyage | From the result screen, reset the run to Day 1 with zero savings. |

Use the mouse for the primary interaction. The game requires no movement controls. Tab/Enter focus behaviour remains on the manual acceptance checklist.

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

The source selects an outcome by probability, then chooses a weight uniformly within that outcome's inclusive integer range. Numeric defaults and display names are stored in `config/default_game_config.tres`.

## Code structure and design

```text
config/         GameConfig and FishDefinition resources
domain/         Catch generation, net, day, settlement and run rules
presentation/   GameController, GameView and FishingView
scenes/         Main scene and interface scene
tests/          Headless rule tests, actual-scene UI tests and test helpers
docs/           Development explanations and acceptance records
project.godot   Editor settings and main-scene entry point
```

`GameSession` owns progression and coin payment. `FishingDay` owns casting, bait and daily end conditions. `FishingNet` stores catches. `SettlementRules` calculates a `DayResult` without paying coins itself. State guards prevent duplicate settlements and skipped days.

`FishingDay` receives the small abstract `CatchSource` contract. `RandomCatchSource` supplies normal gameplay, while test-only `FixedCatchSource` supplies reproducible outcomes. Fish sizes differ through `FishDefinition` data rather than subclasses without different behaviour.

`GameController` connects input to the model. `GameView` displays state and results, and `FishingView` draws the scenery. Domain code has no dependency on scene nodes or buttons, although it uses Godot types such as `RefCounted` and `Resource`.

The Class Map PowerPoint and short design rationale Word document are **separate deliverables outside this Godot project**. Supply them with the final submission and keep them aligned with the frozen source version.

## Verification

From the project root, use the console executable defined above:

```powershell
& $godot --headless --editor --path . --import
if ($LASTEXITCODE -ne 0) { throw 'Godot import failed.' }

$testSuites = @(
    'foundation', 'initialization', 'casting',
    'settlement', 'progression', 'ui', 'review'
)
foreach ($suite in $testSuites) {
    & $godot --headless --path . --script "res://tests/test_$suite.gd"
    if ($LASTEXITCODE -ne 0) { throw "Failed test suite: $suite" }
}
```

Recorded results for the implementation at commit `63f5992`:

| Suite | Checks | Failures |
| --- | ---: | ---: |
| Foundation | 41 | 0 |
| Initialization | 44 | 0 |
| Casting | 54 | 0 |
| Settlement | 50 | 0 |
| Progression | 408 | 0 |
| UI | 79 | 0 |
| Review regressions | 12 | 0 |
| **Total** | **688** | **0** |

These results cover the recorded source version and do not guarantee untested changes or environments. Tests include probability boundaries, 21/22 kg limits, mandatory retention, ending priority, repeated input, settlement idempotence, all seven days, failure with savings and restart.

`test_ui.gd` instantiates the production scene, uses a fixed catch source, and triggers actual button-signal connections to reproduce victory, bust and restart. It runs headlessly and does not replace mouse/keyboard or visual checks. `test_progression.gd` includes a mixed seven-day scenario with expected final savings of **520 gold**.

See [the acceptance checklist](docs/stage_1_acceptance.md) for observed manual results and outstanding items. Its 676-check table is the earlier baseline before the 12 review regressions; the later total is 688.

## Known limitations

- Basic native 2D scenery and casting animation, with no audio, save/load or dedicated fullscreen toggle.
- Shops, upgrades, items and a fish catalogue are outside Stage 1 scope.
- Only Windows with the tested Godot version has been verified.
- Some manual acceptance items remain open, including a complete live seven-day demonstration and keyboard navigation.
- Godot's embedded game preview may display at 1.0× with surrounding margins. This is separate from resizing the standalone game window.

## GitHub and assessment evidence

- [Repository](https://github.com/Peggyyyyyyyy123/fishing-21)
- [Current personal branch: LPQ/featrue-stage1](https://github.com/Peggyyyyyyyy123/fishing-21/tree/LPQ/featrue-stage1)
- [Branch commit history](https://github.com/Peggyyyyyyyy123/fishing-21/commits/LPQ/featrue-stage1)
- [Pull requests](https://github.com/Peggyyyyyyyy123/fishing-21/pulls)
- [Published tags](https://github.com/Peggyyyyyyyy123/fishing-21/tags)

The branch spelling above matches the repository. No frozen `stage-1` tag existed when this README was prepared. Add the exact tag and relevant merge/PR links after review, integration and a clean-checkout run; keep frozen stage tags unchanged.

Before assessment submission, complete the remaining evidence:

- Identify all group members and each person's branch/contribution.
- Record the actual integration PR or merge links. Do not treat a branch push as merge evidence.
- Preserve each student's complete chronological AI prompts and responses in that student's branch or a clearly linked repository location. The logs are **not yet organised in this project**; these design notes are not a substitute for them.
- Include the separate Class Map and design rationale, final run instructions and the required group report/declarations in the submission package.

## Development notes

- [Foundation](docs/stage_1_foundation.md)
- [Initialization](docs/stage_1_initialization.md)
- [Casting](docs/stage_1_casting.md)
- [Settlement](docs/stage_1_settlement.md)
- [Progression](docs/stage_1_progression.md)
- [Interface](docs/stage_1_ui.md)

These notes describe successive implementation steps. Later notes extend earlier snapshots of project capability.
