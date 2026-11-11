# Class Map — Stage 1 (`stage-1`)

Drawn from the code at the [`stage-1` tag](https://github.com/Peggyyyyyyyy123/fishing-21/tree/stage-1). The tag itself is frozen, so this map was added afterwards on the Stage 2 branch. It describes Stage 1 code only.

Connector labels: **is-a** (inheritance), **has-a** (owns a long-lived part), **uses** (calls or reads it while working), **creates** (constructs instances). Formal UML notation is not used.

```mermaid
flowchart LR
  subgraph CFG["Configuration (data resources)"]
    GameConfig["<b>GameConfig</b><br/>Run settings: slots, bait, 21 kg cap,<br/>price, multiplier, daily rents<br/>validate(), get_total_days()"]
    FishDefinition["<b>FishDefinition</b><br/>One catch outcome: id, name,<br/>probability, weight range, is_empty_catch"]
  end

  subgraph DOM["Domain / game rules (no scene nodes)"]
    GameSession["<b>GameSession</b><br/>Run lifecycle state machine,<br/>day number, coins<br/>start_new_game(), start_day(),<br/>settle_day(), advance_day()"]
    FishingDay["<b>FishingDay</b><br/>One day: bait, end reason<br/>cast(), return_to_shore(), can_cast()"]
    FishingNet["<b>FishingNet</b><br/>Holds the day's fish; slots and 21 kg cap<br/>add_fish(), is_full(), is_busted()"]
    Fish["<b>Fish</b><br/>Value object: species id, weight"]
    CatchSource["<b>CatchSource</b> «abstract»<br/>draw() → Fish or null"]
    RandomCatchSource["<b>RandomCatchSource</b><br/>Weighted outcome, uniform integer weight"]
    CastResult["<b>CastResult</b><br/>Outcome of one cast request"]
    SettlementRules["<b>SettlementRules</b><br/>Income: weight × price, ×2 at exactly 21 kg,<br/>0 on bust. calculate(day)"]
    DayResult["<b>DayResult</b><br/>Settlement snapshot: income, rent, pass/fail"]
  end

  subgraph PRE["Presentation (Godot nodes)"]
    GameController["<b>GameController</b> (Node)<br/>Connects button intents to the model;<br/>cast animation lock"]
    GameView["<b>GameView</b> (Control)<br/>HUD, net slots, menu and result overlays;<br/>emits intent signals"]
    FishingView["<b>FishingView</b> (Control)<br/>Draws sea, boat, casting animation"]
  end

  subgraph TST["Test support"]
    FixedCatchSource["<b>FixedCatchSource</b><br/>Scripted catch sequence"]
  end

  GameConfig -- has-a --> FishDefinition
  GameSession -- uses --> GameConfig
  GameSession -- has-a --> FishingDay
  GameSession -- has-a --> SettlementRules
  GameSession -- creates --> RandomCatchSource
  FishingDay -- has-a --> FishingNet
  FishingDay -- uses --> CatchSource
  FishingDay -- creates --> CastResult
  FishingNet -- has-a --> Fish
  RandomCatchSource -- is-a --> CatchSource
  FixedCatchSource -- is-a --> CatchSource
  RandomCatchSource -- uses --> FishDefinition
  RandomCatchSource -- creates --> Fish
  SettlementRules -- uses --> FishingDay
  SettlementRules -- creates --> DayResult
  GameController -- has-a --> GameSession
  GameController -- has-a --> GameView
  GameView -- has-a --> FishingView
  GameView -- uses --> GameSession
```

## Classes and responsibilities

| Layer | Class | Main responsibility | Key attributes / methods |
| --- | --- | --- | --- |
| Config | `GameConfig` | All tunable numbers for one run; validation | `net_slots`, `bait_per_day`, `weight_cap_kg`, `price_per_kg`, `perfect_multiplier`, `daily_quotas`, `fish_definitions`, `validate()` |
| Config | `FishDefinition` | Data for one catch outcome, so a new fish size is data, not a subclass | `species_id`, `probability`, `min_weight_kg`, `max_weight_kg`, `is_empty_catch` |
| Domain | `GameSession` | Seven-day run: states, day advance, paying coins once per settled day | `State` enum, `start_day()`, `settle_day()`, `advance_day()` |
| Domain | `FishingDay` | One day's casting, bait and end conditions (bust > full net > no bait) | `cast()`, `return_to_shore()`, `get_end_reason()` |
| Domain | `FishingNet` | Stores catches; reports full and busted | `add_fish()`, `get_total_weight_kg()` |
| Domain | `Fish` | Immutable catch value | `species_id`, `weight_kg` |
| Domain | `CatchSource` | Abstract source of catches; lets tests replace randomness | `draw()` |
| Domain | `RandomCatchSource` | Normal gameplay draws | weighted pick, uniform weight |
| Domain | `CastResult` | REJECTED / EMPTY / CAUGHT / SOURCE_ERROR for the UI | `get_status()`, `get_fish()` |
| Domain | `SettlementRules` | Computes income without paying it | `calculate(day)` |
| Domain | `DayResult` | Immutable settlement result | `is_passed()`, `get_coin_gain()` |
| Presentation | `GameController` | Input → model calls; locks input during casting | signal handlers, `catch_source_factory` |
| Presentation | `GameView` | Displays snapshots; emits `cast_requested`, etc. | `render()`, `show_result()` |
| Presentation | `FishingView` | Scenery drawing only | `set_casting()` |
| Test | `FixedCatchSource` | Reproducible catches for tests and demos | sequence of `Fish` |

## Core vs presentation

The domain classes extend `RefCounted` and never reference buttons or scene nodes. The presentation classes read snapshots and call domain methods. `GameController.catch_source_factory` and `GameSession.start_day(source)` let a test or live demonstration inject a fixed catch sequence without changing rules.
