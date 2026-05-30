import Foundation

/// Maps Open Food Facts DTOs to domain value types. Mapping lives ONLY in the Data layer.
enum OpenFoodFactsMapper {
    static func map(_ dto: OpenFoodFactsResponseDTO, barcode: String) throws -> ProductLookupResult {
        guard dto.status == 1, let product = dto.product else {
            throw FoodMapError.productNotFound(barcode: barcode)
        }

        let name = product.productNameIt?.nonEmpty
            ?? product.productName?.nonEmpty
            ?? "Unknown product"

        return ProductLookupResult(
            barcode: barcode,
            name: name,
            brand: product.brands?.split(separator: ",").first.map { String($0).trimmingCharacters(in: .whitespaces) },
            category: mapCategory(product.categoriesTags),
            imageURLString: product.imageFrontURL?.nonEmpty ?? product.imageURL?.nonEmpty,
            allergens: mapAllergens(product.allergensTags),
            nutrition: mapNutrition(product.nutriments),
            source: .openFoodFacts
        )
    }

    private static func mapCategory(_ tags: [String]?) -> ProductCategory {
        guard let tags else { return .other }
        let joined = tags.joined(separator: " ")
        if joined.contains("dairy") || joined.contains("milk") || joined.contains("cheese") { return .dairy }
        if joined.contains("meat") || joined.contains("fish") || joined.contains("seafood") { return .meatFish }
        if joined.contains("fruit") || joined.contains("vegetable") { return .fruitsVegetables }
        if joined.contains("bread") || joined.contains("bakery") { return .bakery }
        if joined.contains("frozen") { return .frozen }
        if joined.contains("beverage") || joined.contains("drink") { return .beverages }
        if joined.contains("snack") { return .snacks }
        if joined.contains("sauce") || joined.contains("condiment") { return .condiments }
        return .pantryStaples
    }

    private static let allergenLookup: [String: Allergen] = [
        "gluten": .gluten,
        "crustaceans": .crustaceans,
        "eggs": .eggs,
        "fish": .fish,
        "peanuts": .peanuts,
        "soybeans": .soybeans,
        "milk": .milk,
        "nuts": .nuts,
        "tree-nuts": .nuts,
        "celery": .celery,
        "mustard": .mustard,
        "sesame-seeds": .sesame,
        "sesame": .sesame,
        "sulphur-dioxide-and-sulphites": .sulphites,
        "sulphites": .sulphites,
        "lupin": .lupin,
        "molluscs": .molluscs
    ]

    private static func mapAllergens(_ tags: [String]?) -> [Allergen] {
        guard let tags else { return [] }
        var seen = Set<Allergen>()
        return tags.compactMap { tag in
            let value = tag.replacingOccurrences(of: "en:", with: "")
            guard let allergen = allergenLookup[value], seen.insert(allergen).inserted else { return nil }
            return allergen
        }
    }

    private static func mapNutrition(_ dto: OpenFoodFactsNutrimentsDTO?) -> NutritionSnapshot? {
        guard let dto else { return nil }
        return NutritionSnapshot(
            energyKcal: dto.energyKcal100g,
            proteinGrams: dto.proteins100g,
            carbohydrateGrams: dto.carbohydrates100g,
            fatGrams: dto.fat100g,
            sugarGrams: dto.sugars100g,
            saltGrams: dto.salt100g
        )
    }
}

private extension String {
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
