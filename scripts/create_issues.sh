#!/usr/bin/env bash
set -euo pipefail
export GH_PAGER=cat

# title | labels | phase
issues=(
"Wire AVFoundation barcode capture to live preview in ScannerView|phase:P2,area:ui,type:feature|P2"
"On scan, call ProductLookupService and show product confirmation sheet|phase:P2,area:ui,type:feature|P2"
"Camera permission request and denied-state UX|phase:P2,area:ui,type:feature|P2"
"AddScannedProductToInventory flow from confirmation sheet|phase:P2,area:domain,type:feature|P2"
"Vision OCR capture of expiry date region|phase:P3,area:data,type:feature|P3"
"Feed OCR text into ExpiryDateParser and present candidates|phase:P3,area:ui,type:feature|P3"
"Manual expiry date entry and correction UX|phase:P3,area:ui,type:feature|P3"
"Inventory list grouped by storage location, sorted by expiry|phase:P4,area:ui,type:feature|P4"
"Edit / move / delete / adjust quantity for a product|phase:P4,area:ui,type:feature|P4"
"Empty states and per-location filtering|phase:P4,area:ui,type:feature|P4"
"Schedule local notifications from profile lead days|phase:P5,area:data,type:feature|P5"
"Notification permission request and settings toggle|phase:P5,area:ui,type:feature|P5"
"Generate meal plan prioritizing expiring products (RuleBased)|phase:P6,area:domain,type:feature|P6"
"FoundationModels on-device adapter behind MealPlannerAIService|phase:P6,area:data,type:feature|P6"
"Generate shopping list from meal plan with aggregation|phase:P7,area:domain,type:feature|P7"
"Shopping list check-off, categories, manual add|phase:P7,area:ui,type:feature|P7"
"DesignSystem tokens (color, type, spacing)|phase:P8,area:ui,type:chore|P8"
"Accessibility pass (VoiceOver, Dynamic Type, contrast)|phase:P8,area:ui,type:chore|P8"
"Localization IT/EN|phase:P8,area:ui,type:chore|P8"
"Privacy manifest and App Store assets|phase:P8,area:infra,type:chore|P8"
)

for row in "${issues[@]}"; do
  IFS='|' read -r title labels phase <<< "$row"
  body="Part of roadmap phase **$phase** — see docs/ROADMAP.md and docs/BACKLOG.md.

Acceptance: implement the feature respecting Clean Architecture layering; add/update unit tests; run swiftformat + swiftlint --strict + xcodebuild test on iPhone 17 before commit."
  url=$(gh issue create --title "$title" --body "$body" --label "$labels")
  num=$(basename "$url")
  echo "$num|$phase|$title"
done
