# AGENTS.md — FoodMap

> Single entry point for AI agents and human contributors. Read this first.
> Detailed engineering rules live in [.github/copilot-instructions.md](.github/copilot-instructions.md).

## What this project is
FoodMap — native iOS app (Swift / SwiftUI, **iOS 17+**) for pantry & expiry
management with AI meal planning. Barcode scan → Open Food Facts lookup →
expiry tracking by storage location → alerts → meal plans that prioritize
expiring items → shopping list. **Clean Architecture + MVVM**, SwiftData,
AVFoundation/Vision/UserNotifications, XcodeGen, XCTest.

## How to work here (the loop)
1. **Pick or open an issue.** Every unit of work maps to a GitHub issue. No issue → create one (`gh issue create`).
2. **Branch from `main`:** `feat/<n>-<slug>` for features, `fix/<n>-<slug>` for bugs, `chore/<n>-<slug>` for tooling/docs.
3. **Implement** focused changes only. Respect the layering (Domain → Data → Presentation, deps point inward).
4. **Verify locally before every commit** (mandatory gate):
   ```sh
   xcodegen generate
   swiftformat .
   swiftlint --strict
   xcodebuild -scheme FoodMap -destination 'platform=iOS Simulator,name=iPhone 17' test CODE_SIGNING_ALLOWED=NO
   ```
   All four must pass. **Never commit or push red code.**
5. **Commit** with Conventional Commits (`feat:`, `fix:`, `chore:`, `test:`, `docs:`, `refactor:`). Reference the issue: `Closes #<n>`.
6. **Log the session** — append an entry to `docs/ai-sessions/` (see below).
7. **Open a PR** with `Closes #<n>`; CI must be green before merge.

## Bug-discovery rule (do NOT bury bugs)
Found an unrelated bug mid-task? **Stop.** Open a GitHub issue, fix on a dedicated
`fix/<n>-<slug>` branch from `main`, then return. Pre-existing bugs are never an
exception even if the fix is trivial.

## Where things live
| Path | Purpose |
| --- | --- |
| `FoodMap/Domain/` | Pure Swift: entities, value objects, repository/service protocols, use cases. No SwiftUI/URLSession/DTO. |
| `FoodMap/Data/` | Protocol impls: DTOs, mappers (mapping lives ONLY here), repositories, data sources, persistence, networking. |
| `FoodMap/Features/` | SwiftUI views + `@MainActor` view models. Depend on Domain only. |
| `FoodMap/Core/` | DesignSystem, Errors, Extensions, Utilities, DI helpers. |
| `FoodMap/App/` | `FoodMapApp`, `AppContainer` (composition root), `RootView`. |
| `FoodMapTests/` | XCTest; prefer in-memory SwiftData stores. |
| `docs/` | Roadmap, AI session logs, decisions (ADRs), issue backlog. |
| `.github/agents/` | Custom VS Code subagents (coordinator + specialists). |

## Context & memory for agents (read these to stay oriented)
- **`docs/ROADMAP.md`** — phases P0–P8, current status, what's next.
- **`docs/ai-sessions/`** — chronological log of what each AI session did (newest = current state).
- **`docs/decisions/`** — Architecture Decision Records (ADRs) for non-obvious choices.
- **`docs/BACKLOG.md`** — planned GitHub issues mapped to roadmap phases.
- Agent persistent memory: store repo-scoped facts in `/memories/repo/` and keep `docs/ai-sessions/` authoritative for human-visible history.

## Golden rules
- Tests pass locally before any commit. Lint/format clean (`--strict`).
- Sensitive data (allergies, diets, nutrition) stays on-device; never sent to third parties.
- No secrets in source. No medical claims. Treat scanned text / API responses as untrusted.
- Focused changes; no speculative abstractions.
