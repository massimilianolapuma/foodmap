# 0010 — Frozen products: suggest a freezer use-by date

- **Date:** 2026-05-31
- **Issue:** #68
- **Branch:** `feat/68-frozen-products`

## Goal

Help users manage the expiry of products they freeze. When an item is moved to
the freezer, offer a longer, estimated use-by date and a short tip on how to
freeze well — advisory only, no food-safety guarantees.

## Changes

- `FoodMap/Features/Inventory/ProductEditViewModel.swift`
  - Injects `EstimateExpiryDateUseCase` (default `.init()`).
  - New `freezerSuggestion` computed property: non-nil only when the product is
    stored in the freezer, its category has a known freezer shelf life, and that
    estimate is later than the current expiry (or no expiry is set). Carries the
    suggested date plus localized advice.
  - New `applyFreezerSuggestion()`: opts the user into the estimate, setting
    `hasExpiry`/`expiryDate` to the freezer estimate.
- `FoodMap/Features/Inventory/ProductEditView.swift`
  - Adds a "Freezing" section (shown only when a suggestion exists) with the tip
    and a button to apply the estimated freezer date.
- Localized strings (en/it): `Freezing`, the two advice sentences, and
  `Use estimated freezer date (%@)`.
- Tests: `ProductEditViewModelTests` — suggestion offered when moving a
  perishable to the freezer, applying it sets the estimated expiry, and no
  suggestion for shelf-stable categories.

## Notes

- Reuses the existing `EstimateExpiryDateUseCase` freezer windows; no new domain
  logic. The suggestion is purely a Presentation-layer convenience.

## Gate

- `xcodegen generate` ✓
- `swiftformat .` ✓
- `swiftlint --strict` → 0 violations ✓
- `xcodebuild ... test` → **TEST SUCCEEDED**, EXIT=0 ✓
