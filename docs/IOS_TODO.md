# iOS TODO: Christmas expansion (WORK IN PROGRESS, NOT YET COMPILING)

This branch mirrors the Android `feature/christmas-expansion` work. It was written on Linux, so nothing here has been built in Xcode.

## Done (model layer, matches Android)
- `Game/Data.swift`: levels 6–8 (`maxLevel = 8`, new `levelFor`, `reindeerCount` with Rudolph only at Level 8), new crops (ginger, peppermint), cookies (gingerbread, candy cane, reindeer), toys (rocking horse, yo-yo, snow globe), `Wrap`/`Tree` jobs, `Flight`/`flightFor`, `Deco`, `PetKind`, `Pet`, `meter`, and the new `Place` cases `.park` and `.pets`.
- `Game/GameState.swift`: new `Save` fields, all decoded with defaults (old saves load). Adds wash, decorations, sleigh team (`teamPower`), wrapping, gingerbread house, Town Tree, snowball fight, and pet buying/care with daily gifts. Wrapped presents are delivered first.
- `Game/Sprites.swift`: `Sprites.reindeer(_:decos:)` and the `ReindeerPx` view (Rudolph's nose glows).
- `Resources/sprites.txt`: copied from Android (new toys, cookies, crops, pets, reindeer decorations).
- `HubView`: the reindeer buddy now shows the sleigh team's decorations.

## Still to do (expect compile errors until these are done)
1. **Exhaustive switches**: every `switch` over `Place`, `Toy` and `JobKind` needs the new cases. Known spots: `MiniGames.swift` (`kindsFor`, `paintChar`, `fillHint`, `fillPuff` for the 3 new toys), `Style.swift` `placeBackground`, the place router in `ChristmasTownApp.swift`, the music picker, and the hub badges in `HubView.swift`.
2. **Views to port** from Android:
   - `Stable.kt`: reindeer grid, then a full-screen care screen (feed, brush, wash, dress up, sleigh team). Replaces `StableView`/`ReindeerCard`.
   - `MoreGames.kt`: `WrapGame` (Workshop "Wrap" tab), `GingerbreadGame` (Bakery button), `ParkScreen` with `TreeGame` and `SnowballGame`, plus the new steerable `DeliveryScreen` (clouds, chimneys, fog lit by Rudolph). Replaces the delivery in `SantaViews.swift`. Fix the target to be captured once at the start of the ride (Android commit ea8fcd4).
   - `Pets.kt`: `PetsScreen` (shop + feed/wash/cuddle care) and `WanderingPet` in the living room.
   - `Ui.kt` `unlocksFor`: text for Levels 6–8.
3. **Check on a Mac**: `xcodegen generate`, build, then play through: Level 8 save, a sleigh flight at Level 8 (fog + Rudolph), the pet meters going down over time, and an old save loading.
