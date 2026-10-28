# Repository Guidelines

## Project Structure & Module Organization

Puzzlium is an offline-first SwiftUI jigsaw game for iOS 17 and later. `App/` contains the composition root, configuration, asset catalog, and privacy manifest. `Packages/PuzzliumKit/Sources/` contains six modules: Core, Domain, Engine, Data, DesignSystem, and Features. Package tests live under `Packages/PuzzliumKit/Tests/`; UI smoke tests are in `UITests/`. Generator scripts are in `scripts/`.

Keep the dependency direction `Features → Domain ← Data`; the engine has no dependencies on other project modules. Put SwiftUI screens and observable view models in Features, persistence and networking implementations in Data, and business contracts in Domain.

## Build, Test, and Development Commands

- `xcodegen generate` creates the uncommitted `Puzzlium.xcodeproj` from `project.yml`; then open it in Xcode to run the app. Install XcodeGen first if needed.
- `xcodebuild build -project Puzzlium.xcodeproj -scheme Puzzlium -destination 'platform=iOS Simulator,name=iPhone 17 Pro'` builds the app.
- `cd Packages/PuzzliumKit && xcodebuild test -scheme PuzzliumKit-Package -destination 'platform=iOS Simulator,name=iPhone 17 Pro'` runs package tests.
- `xcodebuild test -project Puzzlium.xcodeproj -scheme Puzzlium -destination 'platform=iOS Simulator,name=iPhone 17 Pro'` runs the app's UI smoke test. Substitute an installed simulator when necessary.
- `python3 scripts/generate_strings.py` regenerates localization catalogs after editing the script; commit both generated files.

## Coding Style & Naming Conventions

Use Swift 6, four-space indentation, and the conventions of surrounding code. Name types in `UpperCamelCase` and functions, properties, and variables in `lowerCamelCase`. Keep views and view models in their feature directories, and reuse existing design-system components. Respect strict concurrency and preserve offline behavior. No repository-wide formatter or lint configuration is currently provided.

## Testing Guidelines

Package tests use Swift Testing; UI tests use XCTest. Add focused tests alongside the relevant Domain, Engine, or Data tests, using descriptive test names that state the behavior. Run the affected package tests for logic changes and the UI smoke test for changes to the main user flow. Coverage is collected by the app scheme; no minimum threshold is specified.

## Commit & Pull Request Guidelines

Recent commits use short, imperative subjects, for example `Skip puzzles solved on earlier days when picking the daily puzzle`. Keep each commit focused. Pull requests should describe the user-visible change, list validation performed, link an issue when applicable, and include screenshots or recordings for visual changes.
