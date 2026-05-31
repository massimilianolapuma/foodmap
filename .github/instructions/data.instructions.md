---
applyTo: "FoodMap/Data/**/*.swift"
---

# Data layer review guidelines

## Purpose

Rules for the Data layer that implements Domain protocols: DTOs, Mappers,
Repositories (impl), DataSources, Persistence (SwiftData), Networking.

## Mapping

- DTO ↔ entity conversion belongs **only** in `Data/Mappers`. Flag mapping logic anywhere else (repositories, view models, use cases).
- DTOs model the wire format; never leak DTOs out of the Data layer.

## Networking (Open Food Facts)

- Networking lives only in `Data/Networking`. HTTPS only; ATS must stay enabled.
- Treat all API responses and scanned text as **untrusted**: validate and bound payloads, decode defensively, and handle missing/invalid fields without crashing.
- Surface failures as typed `FoodMapError` values; never force-unwrap decoded data.

```swift
// Avoid — trusts the response shape
let name = dto.product!.name!

// Prefer — defensive, bounded
guard let product = dto.product, let name = product.name, !name.isEmpty else {
    throw FoodMapError.notFound
}
```

## Persistence

- Use SwiftData `@Model` types. In tests prefer in-memory stores.
- Be mindful of CloudKit constraints if sync is in scope (optional attributes / defaults, no unique constraints).

## Privacy

- Never send allergies, diet types, or nutrition targets to third parties. Process sensitive data on-device.
- No secrets in source.
