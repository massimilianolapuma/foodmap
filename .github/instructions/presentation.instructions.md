---
applyTo: "FoodMap/Features/**/*.swift"
---

# Presentation layer review guidelines

## Purpose

Rules for SwiftUI views and their view models under `Features/`.

## View models

- Mark view models `@MainActor`.
- View models depend on Domain protocols/use cases — **never** on `URLSession`, DTOs, or the Data layer directly.
- Keep shared mutable state isolated; use `async/await` and avoid blocking the main actor.
- Surface user-friendly, localized messages for errors; map typed `FoodMapError` to copy, do not show raw error descriptions.

## Views

- Keep SwiftUI views thin — logic belongs in view models and use cases. Flag views with non-trivial business logic.
- Localize all user-facing strings with `String(localized:)`. Every new key must be added to **both** `FoodMap/Resources/en.lproj/Localizable.strings` and `it.lproj/Localizable.strings`.
- Give interactive elements stable `accessibilityIdentifier`s for UI tests, and meaningful accessibility labels/hints.

## Dependency injection

- Resolve dependencies via `AppContainer` (composition root). Avoid singletons unless strictly necessary.
- When a view model owns a use case via a default initializer, do not claim `AppContainer` exposes it unless it actually does (keep docs/session notes accurate).

## Consistency

- When a displayed flag/field can be changed by the user, ensure the edit flow updates it and the view reflects the change.
