# iOS TODO: Christmas expansion

This branch mirrors the Android `feature/christmas-expansion` work (same rules, numbers, art). It was written on Linux, so **nothing here has been compiled**. Expect a round of small compile fixes in Xcode.

## What's ported
- **Model** (`Game/Data.swift`, `Game/GameState.swift`): levels 6–8 (Rudolph only at Level 8), new crops/cookies/toys, Wrap and Tree jobs, `flightFor` difficulty, reindeer decorations and sleigh team, pets with meters and daily gifts. New `Save` fields all decode with defaults, so old saves load.
- **Art**: `Resources/sprites.txt` copied from Android. `ReindeerPx` in `Game/Sprites.swift` draws decorations and Rudolph's glowing nose.
- **Views**:
  - `StableViews.swift`: reindeer grid, then a close-up care screen (feed, brush, bubble bath, dress up, sleigh team). Also the shared `Tabs` and `Bar` helpers.
  - `WrapGames.swift`: wrapping presents (Workshop tab) and the gingerbread house (Bakery button).
  - `ParkViews.swift`: Snow Park with the Town Tree and the snowball fight.
  - `FlightView.swift`: the new steerable sleigh flight (replaces the old `DeliveryView`).
  - `PetViews.swift`: pet shop, pet care, pets wandering the living room.
  - `CollectViews.swift`: advent calendar (real December dates) and sticker book, opened from the 📅 and 📒 buttons at the bottom of the hub.
  - Hub badges, music, backgrounds, level-up text and the place router include Snow Park, Pets, Advent and Stickers.
- **Items 3–5**: new clothes (pajamas, snowsuit, earmuffs, top hat), furniture/decor (rocking chair, toy chest, nutcracker, sled), new elves Holly and Frost (with chat personality in `Chat.swift`; the Friends row now scrolls), and five new songs in `Resources/Sounds` (O Christmas Tree, Up on the Housetop, Jolly Old St Nicholas, Good King Wenceslas, Twelve Days).
- **Stickers** use the same ids as Android (Kotlin enum names, e.g. `cookie:BerryJam`), built from the Swift raw values with a capital first letter.
- Version bumped to 0.6 (build 6) in `project.yml`.

## Check on a Mac
1. `xcodegen generate`, then build. Likely spots for compile errors: `ForEach` over tuples/arrays without `Identifiable` ids, `@Observable` classes created in `init` via `State(initialValue:)` (`FlightView`), and any `switch` I missed over `Place`, `Toy` or `JobKind`.
2. Gestures: the care screens and Snow Park combine a `DragGesture` with a tap gesture on the same view. Check taps still register and drags don't also fire taps.
3. Check the advent calendar on a December date (change the device date) and that a door can't be opened twice. Check sticker prizes can only be claimed once.
4. Play through with a Level 8 save: wrap a present, build a gingerbread house, decorate the Town Tree, play a snowball fight, fly a foggy Level 8 delivery with Rudolph hitched, adopt a pet and feed/wash/cuddle it, dress a reindeer and check the decorations show in the Stable, hub and sleigh.
5. Load an old (pre-expansion) save and check nothing is lost.
6. iPad: the stage is scaled, but check the 7-icon columns on the hub still fit.

## Follow-up branch `feature/house-and-main-pet`
- Main pet (pick it in Pets; sits in front of you on the main screen) and a house that starts with two storeys and can add an Attic Playroom ($3,000) and a Starlight Loft ($6,000). Tap a room in Decorate to zoom in and see the pets in it and what's happening. New `Save` fields `floors` (default 2) and `mainPet` (default 0 = first pet).
- Check on a Mac: tapping a room vs dragging furniture on top of it in `HouseViews.swift` (furniture should win the drag), and the zoomed `RoomScene` sizing.
