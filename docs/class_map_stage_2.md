# Class Map — Stage 2 (`stage-2`)

Stage 2 adds a visible, finite daily sea and next-cast odds. **New** classes are marked ★, **modified** classes are marked ✎, and the rest are unchanged from [Stage 1](class_map_stage_1.md).

Connector labels: **is-a**, **has-a**, **uses**, **creates**.

```mermaid
flowchart LR
  subgraph CFG["Configuration (data resources)"]
    GameConfig["<b>GameConfig</b> ✎<br/>+ sea_pool_size (0 = Stage 1 draws)<br/>validate()"]
    FishDefinition["<b>FishDefinition</b><br/>Outcome data: probability, weight range"]
  end

  subgraph DOM["Domain / game rules (no scene nodes)"]
    GameSession["<b>GameSession</b> ✎<br/>Run state machine, coins<br/>+ get_next_cast_forecast()<br/>+ _create_default_source()"]
    FishingDay["<b>FishingDay</b> ✎<br/>Casting, bait, ending<br/>+ get_next_cast_chances()<br/>+ get_sea_remaining_counts()"]
    FishingNet["<b>FishingNet</b><br/>Slots and 21 kg cap"]
    Fish["<b>Fish</b><br/>species id, weight"]
    CatchSource["<b>CatchSource</b> «abstract» ✎<br/>draw()<br/>+ get_next_draw_chances()<br/>+ get_initial / remaining_counts()"]
    RandomCatchSource["<b>RandomCatchSource</b> ✎<br/>Independent draws<br/>+ reports its fixed odds"]
    SeaPoolCatchSource["<b>SeaPoolCatchSource</b> ★<br/>Stocks N outcomes at dawn,<br/>draws without replacement"]
    CatchForecast["<b>CatchForecast</b> ★<br/>Break / exactly-21 / empty odds<br/>calculate(definitions, chances, weight, cap)"]
    CastResult["<b>CastResult</b>"]
    SettlementRules["<b>SettlementRules</b><br/>Income calculation (unchanged)"]
    DayResult["<b>DayResult</b>"]
  end

  subgraph PRE["Presentation (Godot nodes)"]
    GameController["<b>GameController</b><br/>Input → model"]
    GameView["<b>GameView</b> ✎<br/>HUD, net, overlays;<br/>rent in kg; weight-bar risk tint"]
    SeaReportPanel["<b>SeaReportPanel</b> ★ (PanelContainer)<br/>Sea counts, ranges, next-cast odds<br/>render(day, config, forecast)"]
    FishingView["<b>FishingView</b> ✎<br/>Scenery (sun moved)"]
  end

  subgraph TST["Test support"]
    FixedCatchSource["<b>FixedCatchSource</b>"]
  end

  GameConfig -- has-a --> FishDefinition
  GameSession -- uses --> GameConfig
  GameSession -- has-a --> FishingDay
  GameSession -- has-a --> SettlementRules
  GameSession -- creates --> SeaPoolCatchSource
  GameSession -- creates --> RandomCatchSource
  GameSession -- creates --> CatchForecast
  FishingDay -- has-a --> FishingNet
  FishingDay -- uses --> CatchSource
  FishingDay -- creates --> CastResult
  FishingNet -- has-a --> Fish
  RandomCatchSource -- is-a --> CatchSource
  SeaPoolCatchSource -- is-a --> CatchSource
  FixedCatchSource -- is-a --> CatchSource
  SeaPoolCatchSource -- uses --> FishDefinition
  CatchForecast -- uses --> FishDefinition
  SettlementRules -- uses --> FishingDay
  SettlementRules -- creates --> DayResult
  GameController -- has-a --> GameSession
  GameController -- has-a --> GameView
  GameView -- has-a --> SeaReportPanel
  GameView -- has-a --> FishingView
  GameView -- uses --> GameSession
  SeaReportPanel -- uses --> CatchForecast
  SeaReportPanel -- uses --> FishingDay
```

## New and changed responsibilities

| Class | Status | Responsibility in Stage 2 |
| --- | --- | --- |
| `SeaPoolCatchSource` | New | A finite sea for one day: random stocking from the configured distribution, draws without replacement, public counts |
| `CatchForecast` | New | Pure calculation of next-cast odds from outcome chances and weight ranges. No state, no engine types |
| `SeaReportPanel` | New | Draws the sea report and odds; owns the risk colour thresholds |
| `CatchSource` | Modified | Added three read-only queries with safe defaults (`{}` = unknown), so `FixedCatchSource` needed no change |
| `RandomCatchSource` | Modified | Reports its fixed odds, so the forecast also works with `sea_pool_size = 0` |
| `FishingDay` | Modified | Passes source queries through to the UI. Casting and ending rules unchanged |
| `GameSession` | Modified | Chooses the default source in one method; exposes the forecast only while a cast is possible |
| `GameConfig` | Modified | `sea_pool_size` with validation (0, or at least daily bait) |
| `GameView` | Modified | Delegates the report to `SeaReportPanel`; shows rent in kg; tints the weight bar |

`FishingNet`, `Fish`, `CastResult`, `SettlementRules`, `DayResult`, `FishDefinition`, `GameController` and `FixedCatchSource` are unchanged.
