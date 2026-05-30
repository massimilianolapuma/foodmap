# ADR-0001 — Clean Architecture + MVVM baseline

**Status:** Accepted · **Date:** 2026-05-30

## Context
FoodMap needs testable domain logic, swappable AI/meal-planning backends, and a
clear boundary between SwiftUI and business rules.

## Decision
Adopt **Clean Architecture + MVVM** with strict inward-pointing dependencies:
- `Domain/` — pure Swift; entities, value objects, repository/service **protocols**, use cases. No SwiftUI / URLSession / DTOs.
- `Data/` — implements Domain protocols; DTOs, mappers (mapping ONLY here), repositories, data sources, persistence (SwiftData), networking (Open Food Facts).
- `Features/` — SwiftUI views + `@MainActor` view models depending on Domain only.
- `Core/` — DesignSystem, Errors, Extensions, Utilities, DI helpers.
- `App/` — `AppContainer` as composition root.

AI meal planning sits behind `MealPlannerAIService`: a deterministic
`RuleBasedMealPlanner` now, an Apple FoundationModels on-device adapter later —
swappable without touching Presentation.

## Consequences
- Domain is unit-testable with in-memory SwiftData stores and fake clocks.
- Backends (networking, AI, persistence) are replaceable behind protocols.
- Extra indirection (protocols + mappers) is accepted as the cost of testability and isolation.
