# FoodMap — Roadmap & Status

> Source of truth for phases and progress. Update the **Status** column as work lands.
> Each phase maps to one or more GitHub issues (see [BACKLOG.md](BACKLOG.md)).

Legend: ✅ done · 🚧 in progress · ⬜ not started

## Phases

| Phase | Title | Status | Notes |
| --- | --- | --- | --- |
| P0 | Project scaffold & tooling | ✅ | XcodeGen, SwiftLint, SwiftFormat, CI, agents, copilot-instructions. |
| P1 | Domain + Data + skeleton UI + test suite | ✅ | Entities, value objects, use cases, OFF networking, SwiftData repos, 5 feature screens, 18 unit tests green. |
| P2 | Barcode scanning end-to-end | ✅ | Live AVFoundation preview, scan→OFF lookup→confirmation sheet→add-to-inventory, permission UX. Issues #1–#4. |
| P3 | Expiry acquisition (manual + OCR) | ✅ | ImagePicker → Vision OCR → candidate dates + manual DatePicker correction. Issues #5–#7. |
| P4 | Inventory management by location | ✅ | Per-location filter, sort by expiry, edit/move/delete/adjust quantity, empty states. Issues #8–#10. |
| P5 | Expiry alerts | ⬜ | UserNotifications scheduling using profile lead days; settings; permission handling. |
| P6 | AI meal planning | ⬜ | RuleBasedMealPlanner first; FoundationModels on-device adapter behind `MealPlannerAIService`. Prioritize expiring items. |
| P7 | Shopping list | ⬜ | Generate from meal plan, aggregate, check-off, categories, manual add. |
| P8 | Polish, accessibility, design system, App Store prep | ⬜ | DesignSystem tokens, a11y, localization (IT/EN), icons, screenshots, privacy manifest. |

## Current focus
- **P2–P4 complete** — scanning, expiry OCR, inventory management, 39 tests green on iPhone 17 simulator.
- **Next:** P5 (expiry alerts).

## Verified build/test commands
```sh
xcodegen generate
swiftformat .
swiftlint --strict
xcodebuild -scheme FoodMap -destination 'platform=iOS Simulator,name=iPhone 17' test CODE_SIGNING_ALLOWED=NO
```

> Simulator note: only the **iPhone 17 family** is installed (17, 17 Pro, 17 Pro Max, 17e). Do NOT use iPhone 16.
