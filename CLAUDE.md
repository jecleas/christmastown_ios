# Christmas Town (iPhone / iPad)

SwiftUI copy of the Android game in `../christmas_town` (branch `hub-redesign`): you're an elf working for Santa. Portrait, pixel art, iPhone + iPad.

**Keep both versions in sync.** Same rules, numbers and content:
- `Game/Data.swift` ↔ `Data.kt`, `Game/GameState.swift` ↔ `GameState.kt`, `Game/Chat.swift` ↔ `Chat.kt` (elf brain + kid-safety filter).
- Art and sound are shared files: `Resources/sprites.txt` is a copy of the Android `assets/sprites.txt`, `Resources/Sounds/*` are copies of Android `res/raw/*` (made by `../christmas_town/tools/make_sounds.py`). If you change one, copy it to the other.
- The saved game (`Save`) decodes every field with a default, so adding fields never breaks old saves.

## Building
- Project is generated: edit `project.yml`, then `xcodegen generate`.
- Use `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` (xcode-select points at CommandLineTools) and put `-derivedDataPath` outside `~/Documents` (iCloud file tags break code signing).
- Signing team `VVA5W6L57V` is a free Apple ID team: profiles last 7 days, and command-line builds can't create profiles for new bundle IDs or devices ("No Accounts"). The first install of a new app/device must be done by pressing Run in Xcode.
- iPhone 12 device id for xcodebuild: `00008101-00021DA12200001E`.

## Clean up when you're done
**Always shut down simulators and background tools when you've finished testing:** `xcrun simctl shutdown all && osascript -e 'quit app "Simulator"'`.
