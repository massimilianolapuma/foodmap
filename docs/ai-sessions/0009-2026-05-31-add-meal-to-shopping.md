# 0009 — Add a single recipe's missing ingredients to the shopping list

- **Date:** 2026-05-31
- **Issue:** #76
- **Branch:** `feat/76-add-meal-to-shopping`

## Goal

Let the user add just one recipe's missing ingredients to the shopping list from
the meal detail screen. Previously only the whole meal plan could be added.

## Changes

- `FoodMap/Domain/UseCases/MealPlanningUseCases.swift`
  - New `GenerateShoppingListFromMealUseCase` (pure domain): builds a shopping
    list from a single meal's ingredients not in the pantry, aggregating
    duplicates by `name+unit`, optionally tagging `sourceMealPlanID`. Mirrors the
    existing plan-level use case.
- `FoodMap/Features/MealPlanner/MealPlannerViewModel.swift`
  - Injects `GenerateShoppingListFromMealUseCase` via its default initializer
    (`.init()`); the view model owns the use case — `AppContainer` is not
    changed and still only exposes `GenerateShoppingListFromMealPlanUseCase`.
  - New `addMealToShoppingList(_:)`: generates from the meal using the current
    `plan?.id`, reuses the existing private `merge(_:)` so items merge into
    matching rows instead of duplicating, surfaces a confirmation, and confirms
    the pantry when nothing is missing.
- `FoodMap/Features/MealPlanner/MealDetailView.swift`
  - New **Add to shopping list** button (`mealDetail.addToShoppingButton`) shown
    when a view model is available, plus a local confirmation alert.
- Localized strings (en/it): `Add to shopping list` + accessibility hint.
- Tests:
  - `MealPlanningUseCasesTests`: single-meal aggregation (case-insensitive),
    pantry items excluded, `sourceMealPlanID` set, empty when all in pantry.
  - `MealPlannerViewModelTests`: adds only that meal's missing items; confirms
    pantry when nothing is missing.

## Gate

- `xcodegen generate` ✓
- `swiftformat .` ✓
- `swiftlint --strict` → 0 violations ✓
- `xcodebuild ... test` → **TEST SUCCEEDED**, EXIT=0 ✓

## Notes

- Reuses the view model's merge logic, so per-meal and whole-plan adds share the
  same de-duplication and confirmation behaviour.
- PR #82.
