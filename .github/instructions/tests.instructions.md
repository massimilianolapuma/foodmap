---
applyTo: "FoodMapTests/**/*.swift,FoodMapUITests/**/*.swift"
---

# Test review guidelines

## Purpose

Rules for unit tests (`FoodMapTests`) and UI tests (`FoodMapUITests`).

## Coverage and intent

- New features and bug fixes require tests. A bug fix should add a regression test that fails without the fix.
- Cover the happy path, edge cases, and error/invalid-input conditions.
- Test names must clearly describe the behavior under test.
- The project targets **≥ 80% line coverage** over the logic layers (Domain, Data, Core, App composition, Feature view models). CI enforces a ratchet baseline via `scripts/coverage_gate.py`; add tests to move it up — never lower it to make a build pass. SwiftUI Views / Design System are excluded (covered by `FoodMapUITests`).

## Determinism

- Avoid `.now`, random values, and real network/disk. Inject fixed `Calendar`/`Date` and use in-memory stores or fakes.
- UI tests: wait on stable `accessibilityIdentifier`s, not on timing.

## Structure

- Keep one logical assertion target per test where practical; prefer clear Arrange-Act-Assert.
- Do not weaken assertions (e.g. broad `XCTAssertNotNil`) when a precise expectation is possible.

```swift
// Avoid — non-deterministic
let estimate = useCase(category: .meatFish, storageLocation: .fridge) // uses .now

// Prefer — deterministic, fixed reference date
let estimate = useCase(category: .meatFish, storageLocation: .fridge, from: fixedDate)
```
