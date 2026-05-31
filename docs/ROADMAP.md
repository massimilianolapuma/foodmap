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
| P5 | Expiry alerts | ✅ | SyncExpiryAlertsUseCase, UserProfile.alertsEnabled, permission + settings toggle, re-sync. Issues #11–#12. |
| P6 | AI meal planning | ✅ | RuleBased prioritizes expiring items; FoundationModels on-device adapter (iOS 26+) with fallback. Issues #13–#14. |
| P7 | Shopping list | ✅ | Generate from meal plan (aggregated), check-off, category sections, manual add, Shopping tab. Issues #15–#16. |
| P8 | Polish, accessibility, design system, App Store prep | ✅ | Typography tokens, VoiceOver/Dynamic Type, IT/EN localization, privacy manifest, App Store copy. Issues #17–#20. |
| P9 | Open Food Facts contribution | ⬜ | When a barcode is missing from OFF, let the user attach a front photo + nutrition-label photo and optionally upload the new product to OFF. Issue #35. |
| P10 | iCloud backup & sync | ⬜ | Persist data to the user's private iCloud (SwiftData + CloudKit) so it survives reinstall and syncs across devices; optional Sign in with Apple. Requires developer account + signing. Issue #36. |
| P11 | UX & content expansion | 🚧 | First-launch onboarding, local-account name, guided + representative product images, complete & replaceable recipes, monthly plans, PDF export, multi-diet + diets section, selectable AI model. Issues #42–#52. |

## Current focus
- **All phases P0–P8 complete** — full feature set, 64 tests green on iPhone 17 simulator.
- **Next:** on-device verification (camera/OCR/notifications/FoundationModels) on a real device; App Store assets finalization (screenshots, icon); developer account + signing when ready.
- **Planned (P9–P10):** Open Food Facts contribution (#35) and iCloud backup/sync (#36).
- **In progress (P11):** UX & content expansion — onboarding (#42), local-account name (#48), product images (#43, #44), complete/replaceable recipes (#45, #46), monthly plans (#47), PDF export (#49), multi-diet + diets section (#50, #51), selectable AI model (#52).

## Verified build/test commands
```sh
xcodegen generate
swiftformat .
swiftlint --strict
xcodebuild -scheme FoodMap -destination 'platform=iOS Simulator,name=iPhone 17' test CODE_SIGNING_ALLOWED=NO
```

> Simulator note: only the **iPhone 17 family** is installed (17, 17 Pro, 17 Pro Max, 17e). Do NOT use iPhone 16.
