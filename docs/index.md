---
layout: default
title: FoodMap
---

# FoodMap

**FoodMap** is a native **iOS app (Swift / SwiftUI, iOS 17+)** for pantry &
expiry management with on-device AI meal planning. Scan a product barcode →
look it up on Open Food Facts → track expiry by storage location → get alerts
before items expire → generate meal plans that prioritize expiring items →
build a shopping list.

## Highlights

- **On-device & private** — allergies, diets, and nutrition targets never leave the device.
- **Apple-native** — AVFoundation (barcode), Vision (OCR for expiry dates),
  UserNotifications (alerts), and FoundationModels (on-device AI meal planning on
  iOS 26+, with a rule-based fallback).
- **Clean Architecture + MVVM** with SwiftData persistence and XcodeGen project generation.

> Status: feature phases **P0–P8 complete**.

## Project links

- [Source code on GitHub](https://github.com/massimilianolapuma/foodmap)
- [README](https://github.com/massimilianolapuma/foodmap/blob/main/README.md)
- [Roadmap](https://github.com/massimilianolapuma/foodmap/blob/main/docs/ROADMAP.md)
- [Architecture decisions (ADRs)](https://github.com/massimilianolapuma/foodmap/tree/main/docs/decisions)
- [Privacy policy](https://github.com/massimilianolapuma/foodmap/blob/main/docs/appstore/privacy-policy.md)

## Tech stack

| Area | Choice |
| --- | --- |
| Language | Swift 5.10 / SwiftUI |
| Minimum OS | iOS 17 |
| Persistence | SwiftData |
| Barcode | AVFoundation |
| Expiry OCR | Vision |
| Alerts | UserNotifications |
| On-device AI | FoundationModels (iOS 26+) with rule-based fallback |
| Project gen | XcodeGen |
| CI | GitHub Actions (lint, build, test) + CodeQL |

---

<small>Built with ❤️ for reducing food waste. Licensed under
<a href="https://github.com/massimilianolapuma/foodmap/blob/main/LICENSE">MIT</a>.</small>
