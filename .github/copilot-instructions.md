# FoodMap — Copilot Repository Instructions

FoodMap is a native iOS app (Swift / SwiftUI, **iOS 17+**) for pantry & expiry management with AI meal planning. It scans product barcodes, identifies products via Open Food Facts, tracks expiry by storage location, alerts before items expire, and generates meal plans that prioritize expiring products plus a shopping list.

## Architecture — Clean Architecture + MVVM
Strict layering. Dependencies point inward only.

- **Domain** (`Domain/`) — pure Swift, no framework UI/networking deps.
  - `Entities/`, `ValueObjects/`, `Repositories/` (protocols), `Services/` (protocols), `UseCases/`.
  - Domain must **never** import SwiftUI, depend on Data, or reference `URLSession`/DTOs.
- **Data** (`Data/`) — implements Domain protocols.
  - `DTOs/`, `Mappers/` (DTO ↔ entity, **only here**), `Repositories/` (impl), `DataSources/`, `Persistence/` (SwiftData), `Networking/`.
- **Presentation** (`Features/`) — SwiftUI views + `@MainActor` view models.
  - ViewModels depend on Domain protocols/use cases, **never** on `URLSession` or DTOs.
- **Core** (`Core/`) — `DesignSystem`, `Extensions`, `Utilities`, `Errors`, `DI`.
- **App** (`App/`) — `FoodMapApp`, `AppContainer` (DI composition root), `RootView`.

## Engineering conventions
- Swift concurrency: `async/await`; mark view models `@MainActor`; isolate shared mutable state with actors.
- Dependency injection via `AppContainer`; avoid singletons unless strictly necessary.
- Keep SwiftUI views thin — logic lives in view models and use cases.
- No DTO ↔ entity mixing outside `Data/Mappers`.
- Errors are typed (`Core/Errors`); surface user-friendly messages in Presentation.
- Networking (Open Food Facts) lives only in `Data/Networking`; HTTPS only, ATS enabled, bound/validate responses.
- Persistence via SwiftData `@Model`; prefer in-memory stores in tests.
- Prefer first-party Apple frameworks: AVFoundation (barcode), Vision (OCR), UserNotifications (alerts), FoundationModels (on-device AI, behind a protocol).

## Privacy & security
- Allergies, diet types, and nutrition targets are **sensitive** — minimize data, process on-device, never send to third parties.
- No secrets in source. No inappropriate medical claims in code or copy.
- Treat scanned text and API responses as untrusted input.

## Tooling
- Project generated with **XcodeGen** (`project.yml`) — run `xcodegen generate` after changing it.
- Lint/format: `swiftlint --strict`, `swiftformat .` — must pass before commit.
- Build/test: `xcodebuild -scheme FoodMap -destination 'platform=iOS Simulator,name=iPhone 17' build|test`.
  - Only the **iPhone 17 family** simulators are installed (17, 17 Pro, 17 Pro Max, 17e). Do NOT use iPhone 16.
  - During tests, CoreData `error: ... Failed to create file` log lines are recovery noise — recovery succeeds and tests pass.

## Tracking & context (read these first)
- **`AGENTS.md`** — single entry point: the working loop, where things live, golden rules.
- **`docs/ROADMAP.md`** — phases P0–P8 with current status and verified commands.
- **`docs/BACKLOG.md`** — planned GitHub issues mapped to phases.
- **`docs/ai-sessions/`** — log every session here (template in `_TEMPLATE.md`); newest = latest state.
- **`docs/decisions/`** — ADRs for non-obvious choices.

## Workflow rules
- **Run tests locally and ensure they pass before any commit or push.**
- Every unit of work maps to a GitHub issue; reference it in the commit (`Closes #<n>`).
- Use Conventional Commits (`feat:`, `fix:`, `chore:`, `test:`, `docs:`, `refactor:`).
- Branches: `feat/<n>-<slug>`, `fix/<n>-<slug>`, `chore/<n>-<slug>` from `main`.
- After meaningful work, append a `docs/ai-sessions/` entry.
- Discovered an unrelated bug? Open a GitHub issue, fix on a `fix/<n>-<slug>` branch from `main`, then return — do not bury it in a feature branch.
- Make focused changes only; avoid speculative abstractions and over-engineering.
