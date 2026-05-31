# 0008 — Estimate expiry for perishables without an explicit date

- **Date:** 2026-05-31
- **Issue:** #67
- **Branch:** `feat/67-estimated-expiry`

## Goal

Perishables (fruit, vegetables, fresh meat/fish, dairy, bakery) often ship
without an explicit expiry date. Estimate a conservative use-by date so these
items still surface before they spoil, clearly flagged as an estimate.

## Changes

- `FoodMap/Domain/UseCases/EstimateExpiryDateUseCase.swift` (new)
  - Pure-domain use case mapping (category, storage location) to a conservative
    shelf life in days from a reference date. Returns `nil` for shelf-stable
    categories (pantry staples, beverages, snacks, condiments, frozen, other).
    Freezer storage extends the window substantially.
- `FoodMap/Domain/Entities/Product.swift`
  - Added stored `expiryIsEstimated: Bool = false` (inline default →
    lightweight SwiftData migration) plus matching init parameter, marking when
    `expiryDate` was estimated rather than read from packaging.
- `FoodMap/Domain/UseCases/InventoryUseCases.swift`
  - `AddScannedProductToInventoryUseCase` now estimates an expiry when none is
    provided and the category is perishable, setting `expiryIsEstimated`.
- `FoodMap/Features/Inventory/InventoryView.swift`
  - Inventory row shows an "Estimated expiry" label (and accessibility text)
    when the expiry was estimated.
- Localized strings (en/it): `Estimated expiry`.
- Tests: `EstimateExpiryDateUseCaseTests` (per-category/location windows,
  shelf-stable → nil) and `AddScannedProductEstimatedExpiryTests`
  (estimate on add, explicit date untouched, shelf-stable stays nil).

## Gate

- `xcodegen generate` ✓
- `swiftformat .` ✓
- `swiftlint --strict` → 0 violations ✓
- `xcodebuild ... test` → **TEST SUCCEEDED**, EXIT=0 ✓

## Notes

- Estimates are advisory only — no medical or food-safety claims. Refactored the
  shelf-life table into a `ShelfLife` struct + two small functions to satisfy
  SwiftLint cyclomatic-complexity and large-tuple rules.
