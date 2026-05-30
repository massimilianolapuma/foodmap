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
| [#1](https://github.com/massimilianolapuma/foodmap/issues/1) | P2 | Wire AVFoundation barcode capture to live preview in ScannerView | phase:P2, area:ui, type:feature |
| [#2](https://github.com/massimilianolapuma/foodmap/issues/2) | P2 | On scan, call ProductLookupService and show product confirmation sheet | phase:P2, area:ui, type:feature |
| [#3](https://github.com/massimilianolapuma/foodmap/issues/3) | P2 | Camera permission request + denied state UX | phase:P2, area:ui, type:feature |
| [#4](https://github.com/massimilianolapuma/foodmap/issues/4) | P2 | AddScannedProductToInventory flow from confirmation sheet | phase:P2, area:domain, type:feature |
| [#5](https://github.com/massimilianolapuma/foodmap/issues/5) | P3 | Vision OCR capture of expiry date region | phase:P3, area:data, type:feature |
| [#6](https://github.com/massimilianolapuma/foodmap/issues/6) | P3 | Feed OCR text into ExpiryDateParser and present candidates | phase:P3, area:ui, type:feature |
| [#7](https://github.com/massimilianolapuma/foodmap/issues/7) | P3 | Manual expiry date entry + correction UX | phase:P3, area:ui, type:feature |
| [#8](https://github.com/massimilianolapuma/foodmap/issues/8) | P4 | Inventory list grouped by storage location, sorted by expiry | phase:P4, area:ui, type:feature |
| [#9](https://github.com/massimilianolapuma/foodmap/issues/9) | P4 | Edit / move / delete / adjust quantity for a product | phase:P4, area:ui, type:feature |
| [#10](https://github.com/massimilianolapuma/foodmap/issues/10) | P4 | Empty states + per-location filtering | phase:P4, area:ui, type:feature |
| [#11](https://github.com/massimilianolapuma/foodmap/issues/11) | P5 | Schedule local notifications from profile lead days | phase:P5, area:data, type:feature |
| [#12](https://github.com/massimilianolapuma/foodmap/issues/12) | P5 | Notification permission request + settings toggle | phase:P5, area:ui, type:feature |
| [#13](https://github.com/massimilianolapuma/foodmap/issues/13) | P6 | Generate meal plan prioritizing expiring products (RuleBased) | phase:P6, area:domain, type:feature |
| [#14](https://github.com/massimilianolapuma/foodmap/issues/14) | P6 | FoundationModels on-device adapter behind MealPlannerAIService | phase:P6, area:data, type:feature |
| [#15](https://github.com/massimilianolapuma/foodmap/issues/15) | P7 | Generate shopping list from meal plan with aggregation | phase:P7, area:domain, type:feature |
| [#16](https://github.com/massimilianolapuma/foodmap/issues/16) | P7 | Shopping list check-off, categories, manual add | phase:P7, area:ui, type:feature |
| [#17](https://github.com/massimilianolapuma/foodmap/issues/17) | P8 | DesignSystem tokens (color, type, spacing) | phase:P8, area:ui, type:chore |
| [#18](https://github.com/massimilianolapuma/foodmap/issues/18) | P8 | Accessibility pass (VoiceOver, Dynamic Type, contrast) | phase:P8, area:ui, type:chore |
| [#19](https://github.com/massimilianolapuma/foodmap/issues/19) | P8 | Localization IT/EN | phase:P8, area:ui, type:chore |
| [#20](https://github.com/massimilianolapuma/foodmap/issues/20) | P8 | Privacy manifest + App Store assets | phase:P8, area:infra, type:chore |
