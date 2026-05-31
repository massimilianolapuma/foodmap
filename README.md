# FoodMap

[![CI](https://github.com/massimilianolapuma/foodmap/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/massimilianolapuma/foodmap/actions/workflows/ci.yml)
[![CodeQL](https://github.com/massimilianolapuma/foodmap/actions/workflows/codeql.yml/badge.svg?branch=main)](https://github.com/massimilianolapuma/foodmap/actions/workflows/codeql.yml)
[![Platform](https://img.shields.io/badge/platform-iOS%2017%2B-blue.svg)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.10-orange.svg)](https://swift.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

FoodMap is a native **iOS app (Swift / SwiftUI, iOS 17+)** for pantry & expiry
management with AI meal planning. Scan a product barcode → look it up on Open
Food Facts → track expiry by storage location → get alerts before items expire →
generate meal plans that prioritize expiring items → build a shopping list.

- **On-device & private:** allergies, diets, and nutrition targets never leave the device.
- **Apple-native:** AVFoundation (barcode), Vision (OCR for expiry dates), UserNotifications (alerts), FoundationModels (on-device AI meal planning, iOS 26+ with a rule-based fallback).
- **Clean Architecture + MVVM**, SwiftData persistence, XcodeGen project generation.

> Status: feature phases **P0–P8 complete**. See [docs/ROADMAP.md](docs/ROADMAP.md).

---

## Requirements

| Tool | Version used | Install |
| --- | --- | --- |
| macOS | 14+ (Apple Silicon) | — |
| Xcode | 26.x (iOS 17+ SDK) | App Store |
| XcodeGen | 2.45+ | `brew install xcodegen` |
| SwiftLint | 0.63+ | `brew install swiftlint` |
| SwiftFormat | 0.61+ | `brew install swiftformat` |

> **Simulators:** this project targets the **iPhone 17 family** (17, 17 Pro, 17 Pro Max, 17e). Use one of these as the destination — do **not** use iPhone 16.

---

## Quick start

```sh
# 1. Clone
git clone https://github.com/massimilianolapuma/foodmap.git
cd foodmap

# 2. Generate the Xcode project from project.yml
xcodegen generate

# 3a. Open in Xcode
open FoodMap.xcodeproj
#     then select the "FoodMap" scheme + an iPhone 17 simulator and press ⌘R

# 3b. …or run straight from the command line (see "Run" below)
```

The Xcode project (`FoodMap.xcodeproj`) is **generated** by XcodeGen from
[project.yml](project.yml). Always re-run `xcodegen generate` after editing
`project.yml`; never hand-edit the `.xcodeproj`.

---

## Run

### From Xcode
1. `xcodegen generate`
2. `open FoodMap.xcodeproj`
3. Select the **FoodMap** scheme and an **iPhone 17** simulator.
4. Press **⌘R**.

### From the command line

```sh
# Build for the simulator
xcodebuild -scheme FoodMap \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build CODE_SIGNING_ALLOWED=NO

# Boot the simulator, install and launch the app
xcrun simctl boot 'iPhone 17' 2>/dev/null; open -a Simulator
APP=$(xcodebuild -scheme FoodMap -destination 'platform=iOS Simulator,name=iPhone 17' \
  -showBuildSettings 2>/dev/null | awk -F' = ' '/ BUILT_PRODUCTS_DIR /{d=$2} / FULL_PRODUCT_NAME /{n=$2} END{print d"/"n}')
xcrun simctl install booted "$APP"
xcrun simctl launch booted com.massimilianolapuma.foodmap
```

> Camera-based features (barcode scanning, expiry OCR) and notifications work
> best on a **real device** — the simulator has no camera. The on-device
> FoundationModels meal planner requires an Apple-Intelligence-capable device
> running iOS 26+; on the simulator it automatically falls back to the
> deterministic rule-based planner.

---

## Test

The verification gate (run from the repo root) must pass before any commit:

```sh
xcodegen generate
swiftformat .
swiftlint --strict
xcodebuild -scheme FoodMap \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  test CODE_SIGNING_ALLOWED=NO
```

- **Unit tests** (`FoodMapTests/`) cover use cases, view models, mappers, and
  parsers — they use in-memory SwiftData stores and fakes.
- **UI / E2E tests** (`FoodMapUITests/`) drive the running app in the simulator
  via accessibility identifiers, exercising each feature end-to-end.

Run a single suite:

```sh
# Unit tests only
xcodebuild -scheme FoodMap -destination 'platform=iOS Simulator,name=iPhone 17' \
  test -only-testing:FoodMapTests CODE_SIGNING_ALLOWED=NO

# UI / E2E tests only
xcodebuild -scheme FoodMap -destination 'platform=iOS Simulator,name=iPhone 17' \
  test -only-testing:FoodMapUITests CODE_SIGNING_ALLOWED=NO
```

> During tests, CoreData `error: … Failed to create file` log lines are
> recovery noise — recovery succeeds and tests pass.

---

## Continuous integration

CI is modelled on the [`cubelite`](https://github.com/massimilianolapuma/cubelite)
project and runs on every push to `main`/`feat|fix|chore/**` and on every PR to
`main`:

- **CI** ([.github/workflows/ci.yml](.github/workflows/ci.yml)) — on a macOS
  runner: `xcodegen generate` → `swiftformat --lint .` → `swiftlint --strict` →
  `xcodebuild test` (unit tests) on an iPhone 17 simulator. UI tests are run
  locally (skipped in CI, as in cubelite) because they are slower and flakier on
  hosted runners.
- **CodeQL** ([.github/workflows/codeql.yml](.github/workflows/codeql.yml)) —
  security analysis for `swift` (manual build) and GitHub `actions`, on push, PR,
  and a weekly schedule.

Third-party GitHub Actions are **pinned to commit SHAs** (same convention as
cubelite). `CI` is the required status check for merging into `main`.

---

## Design

The UI is currently implemented **directly in SwiftUI** with a code-based design
system ([FoodMap/Core/DesignSystem](FoodMap/Core/DesignSystem)) — colours,
typography, spacing tokens, and reusable components. There are, as of now, **no
Penpot mockups**: the screens were built straight in code. Producing Penpot
design files (and wiring the Penpot MCP via the `designer` subagent) is tracked
as follow-up work, not yet done.

---

## Agent skills

Evaluation of third-party "agent skills" considered for this project (impeccable,
twostraws/Swift-Agent-Skills, itgoyo/awesome-agent-skills) is documented in
[docs/skills-evaluation.md](docs/skills-evaluation.md).

---

## Project structure

```
FoodMap/
  Domain/        Pure Swift: entities, value objects, repository/service protocols, use cases
  Data/          Protocol impls: DTOs, mappers (mapping lives ONLY here), repositories, data sources, persistence, networking
  Features/      SwiftUI views + @MainActor view models (depend on Domain only)
  Core/          DesignSystem, Camera protocols, Errors, Extensions, Utilities, DI helpers
  App/           FoodMapApp, AppContainer (DI composition root), RootView
  Resources/     Localizable.strings (en/it), InfoPlist.strings, PrivacyInfo.xcprivacy
FoodMapTests/    XCTest unit tests (in-memory SwiftData stores)
FoodMapUITests/  XCUITest end-to-end UI tests
docs/            Roadmap, AI session logs, decisions (ADRs), backlog, App Store assets
project.yml      XcodeGen project definition (source of truth for the .xcodeproj)
```

**Architecture:** Clean Architecture + MVVM. Dependencies point inward only:
`Features → Domain ← Data`. The Domain layer never imports SwiftUI, networking,
or DTOs. DTO ↔ entity mapping happens only in `Data/Mappers`.

---

## Contributing

See [AGENTS.md](AGENTS.md) and [.github/copilot-instructions.md](.github/copilot-instructions.md).

- Tests, lint, and format must pass locally before every commit.
- Conventional Commits (`feat:`, `fix:`, `chore:`, `test:`, `docs:`, `refactor:`); reference the issue (`Closes #<n>`).
- Branch from `main`: `feat/<n>-<slug>`, `fix/<n>-<slug>`, `chore/<n>-<slug>`.
- Found an unrelated bug? Open a GitHub issue and fix it on its own `fix/<n>-<slug>` branch — never bury it in a feature branch.

---

## License

[Apache-2.0](LICENSE).
