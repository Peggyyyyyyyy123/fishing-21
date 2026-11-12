# English fullscreen interface — 2026-11-11

- Start fullscreen at the current monitor resolution. The 1600×900 logical canvas scales to the display while preserving aspect ratio. F11 toggles fullscreen; Esc closes the field guide first, otherwise leaves fullscreen.
- Header: large Day on the left and today's Earned gold on the right. Earned is projected daily settlement income, including discovery and any perfect-catch multiplier, before rent. Voyage savings remain on the result screen.
- Footer: Cast shows remaining bait; Return shows the rent due; Field Guide opens the collection.
- Today's Sea sits above the net at the lower left. Hover or focus reveals the species/count/weight report above the button. Leaving the hover area dismisses it. Background alpha is 0.20, meaning 80% transparent. Next-cast probability sentences have been removed.
- Catch: a blue pixel-style card with a pale border, weight corner, native pixel fish illustration, English name, rarity, gold sale price and optional NEW DISCOVERY badge. The price is the fish's sale value, excluding the discovery reward and perfect multiplier. Keep and Release retain the existing rule behavior. Overweight is identified on the Keep button, with Release focused by default.
- Field guide: parchment two-page book. Select a collected species in the right grid to see its illustration, rarity, biggest weight in grams, catch count and economics on the left. Unknown species appear as silhouettes. All 10 slots fit; scrolling remains available for future expansion.
- All runtime interface strings, names and rarities are English. Pixel fish are code-native assets shared between cards and the collection, without external image dependencies.
- Catalogue schema version 2 stores count, best_weight_kg and last_weight_kg per species in the existing file. Legacy boolean unlocks stay unlocked and do not pay a second discovery bonus. Historical weights/counts are not invented; the guide shows Not recorded until the next catch.

## Verification

Ten test suites: 1,535 assertions, zero failures. The new interface suite covers hover show/hide, background alpha, button data, English runtime text, card fields, book selection, persistent records and legacy save migration. Fullscreen screenshots verify the HUD, sea report, card and book; additional windowed screenshots check scaling at 1280×720. Earlier catch/settlement/progression tests still apply. No balance parameters changed in this revision.
