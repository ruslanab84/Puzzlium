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
- In-app credits screen for the landmark photos (CC BY / CC BY-SA require visible attribution).

## Photo credits

Landmark puzzles (`PuzzliumData/Resources/landmark-*.jpg`) are Wikimedia Commons photos, center-cropped and
resized to 1600×1600.

| File | Author | License | Source |
|------|--------|---------|--------|
| landmark-eiffel-tower | Tristan Nitot | CC BY-SA 3.0 | [Commons](https://commons.wikimedia.org/wiki/File:Tour_eiffel_at_sunrise_from_the_trocadero.jpg) |
| landmark-colosseum | Anil Öztas | CC BY 4.0 | [Commons](https://commons.wikimedia.org/wiki/File:Rom_(IT),_Kolosseum_--_2024_--_0610.jpg) |
| landmark-great-wall | CEphoto, Uwe Aranas | CC BY-SA 3.0 | [Commons](https://commons.wikimedia.org/wiki/File:Badaling_China_Great-Wall-of-China-01.jpg) |
| landmark-taj-mahal | Yann; edited by King of Hearts | CC BY-SA 4.0 | [Commons](https://commons.wikimedia.org/wiki/File:Taj_Mahal,_Agra,_India_edit2.jpg) |
| landmark-giza-pyramids | Ricardo Liberato | CC BY-SA 2.0 | [Commons](https://commons.wikimedia.org/wiki/File:All_Gizah_Pyramids.jpg) |
| landmark-statue-of-liberty | Jakub Hałun | CC BY-SA 4.0 | [Commons](https://commons.wikimedia.org/wiki/File:Statue_of_Liberty,_New_York_City,_20231001_1037_0857.jpg) |
| landmark-machu-picchu | Martin St-Amant (S23678) | CC BY-SA 3.0 | [Commons](https://commons.wikimedia.org/wiki/File:80_-_Machu_Picchu_-_Juin_2009_-_edit.jpg) |
| landmark-sydney-opera-house | Thomas Adams | CC BY-SA 4.0 | [Commons](https://commons.wikimedia.org/wiki/File:Sydneyoperahouse_at_night.jpg) |
| landmark-big-ben | Colin | CC BY-SA 4.0 | [Commons](https://commons.wikimedia.org/wiki/File:Big_Ben_at_sunset_-_2014-10-27_17-30.jpg) |
| landmark-saint-basils | Юрий Д.К. | CC BY 4.0 | [Commons](https://commons.wikimedia.org/wiki/File:Moscow_-_2025_-_Daytime_view_of_St._Basil%27s_Cathedral_from_Vasilyevsky_Spusk.jpg) |
