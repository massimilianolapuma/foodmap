---
applyTo: "FoodMap/Domain/**/*.swift"
---

# Domain layer review guidelines

## Purpose

Rules for the pure-Swift Domain layer (Entities, ValueObjects, Repositories
protocols, Services protocols, UseCases). These instructions supplement the
repository-wide ones.

## Architectural purity

- Domain must never `import SwiftUI`, `import URLSession`, or any networking type.
- Domain must not reference DTOs or depend on the `Data` layer (dependencies point inward only).
- Repositories and Services in Domain are **protocols**; concrete implementations live in `Data`.
- Keep entities and use cases framework-free; `import Foundation` and `import SwiftData` are acceptable for `@Model` entities only.

## Use cases

- Prefer small, single-responsibility use cases. Flag use cases that mix unrelated concerns.
- Use `async/await`; never block. Mark types `Sendable` where they cross concurrency boundaries.
- Validate inputs at the boundary and throw typed errors from `Core/Errors` (e.g. `FoodMapError.invalidInput`). Do not return optionals to signal validation failures.

## Correctness traps to flag

- Date math: when a value is later compared for equality or used as a merge key, normalize it (e.g. `calendar.startOfDay(for:)`) so time-of-day does not leak in and cause duplicate rows.
- When a new persisted field affects display/announcements, verify every create **and** edit/update path sets or clears it consistently.
- Aggregation/merge logic must define a stable key (e.g. `name.lowercased() + "|" + unit`) and merge into matching rows instead of appending duplicates.

```swift
// Avoid — time-of-day leaks into the estimate, breaking equality-based merges
return calendar.date(byAdding: .day, value: days, to: .now)

// Prefer — stable start-of-day reference
let start = calendar.startOfDay(for: referenceDate)
return calendar.date(byAdding: .day, value: days, to: start)
```

## Testing expectations

- New use cases require unit tests covering the happy path, edge cases, and invalid input.
- Prefer deterministic inputs (fixed `Calendar`/dates) over `.now` in tests.
