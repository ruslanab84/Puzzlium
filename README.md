# Puzzlium

Jigsaw puzzle game for iPhone and iPad. SwiftUI, Swift 6, iOS 17+, offline-first.

## Run

```sh
brew install xcodegen        # once
xcodegen generate            # creates Puzzlium.xcodeproj (not committed)
open Puzzlium.xcodeproj
```

Tests:

```sh
# Domain, engine, data (Swift Testing)
cd Packages/PuzzliumKit && xcodebuild test -scheme PuzzliumKit-Package -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
# UI smoke test (home → setup → game → hint → home)
xcodebuild test -project Puzzlium.xcodeproj -scheme Puzzlium -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

## Structure

```
App/                      Composition root (AppContainer), resources, privacy manifest
Packages/PuzzliumKit/
  PuzzliumCore            Logging, analytics contract
  PuzzliumDomain          Entities, repository protocols, use cases (no frameworks)
  PuzzliumEngine          Piece cutting, geometry, snapping, board state, rendering
  PuzzliumData            HTTP client, offline-first catalog, SwiftData, image cache
  PuzzliumDesignSystem    Tokens and reusable components
  PuzzliumFeatures        SwiftUI screens + @Observable view models
UITests/                  XCUITest smoke test
scripts/generate_strings.py   Single source for all UI strings (en, ru)
```

Dependency rule: `Features → Domain ← Data`. Engine depends on nothing.

## Key decisions

- **Board rendering.** Pieces are cut once off the main thread (`PieceImageRenderer`). Placed pieces are
  composited into one bitmap (`BoardCompositor`), so a 400-piece board draws a single image per frame.
- **Deterministic cuts.** Layout is seeded from puzzle id + piece count; saves store only the seed and the
  placed set (≈2 KB), not geometry.
- **Offline-first.** Bundled catalog with on-device art, disk-cached remote catalog refreshed in the
  background, SwiftData progress. The app works fully without network.
- **Localization.** Edit `scripts/generate_strings.py`, run it, commit both generated files.

## Next

- Backend: set `AppConfiguration.apiBaseURL`; contract is `GET v1/catalog` → `{ "puzzles": [PuzzleDTO] }`.
- Firebase: add the SDK to `PuzzliumData` only, implement `AnalyticsTracking` there, swap it in `AppContainer`.
- iCloud sync of progress (`cloudKitDatabase` in `PersistenceFactory`).
- StoreKit 2 puzzle packs.

## Puzzle art

No bundled image puzzles ship right now; `BundledCatalog.puzzles` is empty.
