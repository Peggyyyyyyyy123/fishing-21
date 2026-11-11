# Class Map — Stage 3 (`stage-3`)

Stage 3 adds a species economy, the keep-or-release choice and a persistent fish catalogue. **New** classes are marked ★, **modified** ✎, everything else is unchanged from [Stage 2](class_map_stage_2.md).

Connector labels: **is-a**, **has-a**, **uses**, **creates**.

```mermaid
flowchart LR
  subgraph CFG["Configuration (data resources)"]
    GameConfig["<b>GameConfig</b> ✎<br/>Base price, rents 180–300, sea size"]
    FishDefinition["<b>FishDefinition</b> ✎<br/>+ rarity, price_per_kg (0 = base),<br/>discovery_reward"]
  end

  subgraph DOM["Domain / game rules (no scene nodes)"]
    GameSession["<b>GameSession</b> ✎<br/>Run state machine, coins<br/>+ owns FishCatalog<br/>+ preview_income(), get_fish_value()"]
    FishingDay["<b>FishingDay</b> ✎<br/>Casting, bait, ending<br/>+ pending catch, resolve_catch(keep)<br/>+ get_discoveries()"]
    FishCatalog["<b>FishCatalog</b> ★<br/>Discovered species, counts, best weight<br/>record_catch(), from/to_dictionary()"]
    SettlementRules["<b>SettlementRules</b> ✎<br/>All money rules: species price,<br/>×2 at 21 kg, bust, discovery rewards<br/>preview_income(), calculate()"]
    DayResult["<b>DayResult</b> ✎<br/>+ discovery income"]
    FishingNet["<b>FishingNet</b><br/>Slots and 21 kg cap"]
    Fish["<b>Fish</b>"]
    CatchSource["<b>CatchSource</b> «abstract»"]
    SeaPoolCatchSource["<b>SeaPoolCatchSource</b>"]
    RandomCatchSource["<b>RandomCatchSource</b>"]
    CatchForecast["<b>CatchForecast</b><br/>(used by balance tool and tests;<br/>no longer shown in the UI)"]
    CastResult["<b>CastResult</b>"]
  end

  subgraph PER["Persistence"]
    FishCatalogStore["<b>FishCatalogStore</b> ★ (moved)<br/>Atomic save / load of the catalogue"]
  end

  subgraph PRE["Presentation (Godot nodes)"]
    GameController["<b>GameController</b> ✎<br/>Input → model; saves catalogue after a catch"]
    GameView["<b>GameView</b> ✎<br/>HUD, net, actions, menu/result;<br/>composes components"]
    SeaReportPanel["<b>SeaReportPanel</b> ✎<br/>Hover sea report"]
    CatchCard["<b>CatchCard</b> ★<br/>Keep / release card"]
    FieldGuideBook["<b>FieldGuideBook</b> ★<br/>Two-page catalogue"]
    FishArt["<b>FishArt</b> ★<br/>Code-drawn pixel fish"]
    UiKit["<b>UiKit</b> ★<br/>Static layout helpers, theme"]
    FishingView["<b>FishingView</b>"]
  end

  GameConfig -- has-a --> FishDefinition
  GameSession -- uses --> GameConfig
  GameSession -- has-a --> FishingDay
  GameSession -- has-a --> SettlementRules
  GameSession -- has-a --> FishCatalog
  GameSession -- creates --> SeaPoolCatchSource
  FishingDay -- uses --> FishCatalog
  FishingDay -- has-a --> FishingNet
  FishingDay -- uses --> CatchSource
  FishingDay -- creates --> CastResult
  FishingNet -- has-a --> Fish
  SeaPoolCatchSource -- is-a --> CatchSource
  RandomCatchSource -- is-a --> CatchSource
  SettlementRules -- uses --> FishDefinition
  SettlementRules -- uses --> FishingDay
  SettlementRules -- creates --> DayResult
  FishCatalogStore -- creates --> FishCatalog
  GameController -- has-a --> GameSession
  GameController -- has-a --> FishCatalogStore
  GameController -- has-a --> GameView
  GameView -- has-a --> SeaReportPanel
  GameView -- has-a --> CatchCard
  GameView -- has-a --> FieldGuideBook
  GameView -- has-a --> FishingView
  GameView -- uses --> GameSession
  CatchCard -- has-a --> FishArt
  FieldGuideBook -- has-a --> FishArt
  FieldGuideBook -- uses --> FishCatalog
  GameView -- uses --> UiKit
  CatchCard -- uses --> UiKit
  FieldGuideBook -- uses --> UiKit
  SeaReportPanel -- uses --> UiKit
```

`FixedCatchSource` (test) is still a `CatchSource`. New test helpers: `KeepEveryCatch` (a player who keeps every catch) and `LegacyTestConfig` (Stage 1 fish and rents).

## Responsibilities that moved or appeared

| Responsibility | Stage 2 owner | Stage 3 owner | Why |
| --- | --- | --- | --- |
| Price of a fish | `SettlementRules` (one global price) | `SettlementRules` (species price or base price) | Money stays in one class; preview and settlement cannot disagree |
| Discovery reward | — | `SettlementRules`, from `FishingDay.get_discoveries()` | The day records *facts*; the rules turn facts into gold |
| Which species are discovered, counts, best weight | — | `FishCatalog` | Outlives a voyage and changes for different reasons than a day |
| Saving the catalogue | — | `FishCatalogStore` in `persistence/` | File I/O is infrastructure, not a game rule |
| The keep/release decision | — (forced keep) | `FishingDay.resolve_catch()` | Same object that owns the net and bait |
| Catch card, field guide | — | `CatchCard`, `FieldGuideBook` | Keeps `GameView` from becoming a god class |
