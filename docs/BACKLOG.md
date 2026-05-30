# FoodMap — Issue Backlog

> Planned GitHub issues mapped to roadmap phases. Create these with `gh issue create`
> (or the GitHub MCP tools) and keep the **#** column updated once filed.
> Labels: `phase:Px`, `area:domain|data|ui|infra`, `type:feature|bug|chore|test|docs`.

## How to file
```sh
gh issue create --title "<title>" --body-file <(echo "<body>") \
  --label "phase:P2,area:ui,type:feature"
```

## Backlog

| # | Phase | Title | Labels |
| --- | --- | --- | --- |
| — | P2 | Wire AVFoundation barcode capture to live preview in ScannerView | phase:P2, area:ui, type:feature |
| — | P2 | On scan, call ProductLookupService and show product confirmation sheet | phase:P2, area:ui, type:feature |
| — | P2 | Camera permission request + denied state UX | phase:P2, area:ui, type:feature |
| — | P2 | AddScannedProductToInventory flow from confirmation sheet | phase:P2, area:domain, type:feature |
| — | P3 | Vision OCR capture of expiry date region | phase:P3, area:data, type:feature |
| — | P3 | Feed OCR text into ExpiryDateParser and present candidates | phase:P3, area:ui, type:feature |
| — | P3 | Manual expiry date entry + correction UX | phase:P3, area:ui, type:feature |
| — | P4 | Inventory list grouped by storage location, sorted by expiry | phase:P4, area:ui, type:feature |
| — | P4 | Edit / move / delete / adjust quantity for a product | phase:P4, area:ui, type:feature |
| — | P4 | Empty states + per-location filtering | phase:P4, area:ui, type:feature |
| — | P5 | Schedule local notifications from profile lead days | phase:P5, area:data, type:feature |
| — | P5 | Notification permission request + settings toggle | phase:P5, area:ui, type:feature |
| — | P6 | Generate meal plan prioritizing expiring products (RuleBased) | phase:P6, area:domain, type:feature |
| — | P6 | FoundationModels on-device adapter behind MealPlannerAIService | phase:P6, area:data, type:feature |
| — | P7 | Generate shopping list from meal plan with aggregation | phase:P7, area:domain, type:feature |
| — | P7 | Shopping list check-off, categories, manual add | phase:P7, area:ui, type:feature |
| — | P8 | DesignSystem tokens (color, type, spacing) | phase:P8, area:ui, type:chore |
| — | P8 | Accessibility pass (VoiceOver, Dynamic Type, contrast) | phase:P8, area:ui, type:chore |
| — | P8 | Localization IT/EN | phase:P8, area:ui, type:chore |
| — | P8 | Privacy manifest + App Store assets | phase:P8, area:infra, type:chore |
