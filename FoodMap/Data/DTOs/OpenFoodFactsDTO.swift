import Foundation

/// Open Food Facts API response envelope. Data-layer only.
struct OpenFoodFactsResponseDTO: Decodable {
    let status: Int
    let code: String?
    let product: OpenFoodFactsProductDTO?
}

struct OpenFoodFactsProductDTO: Decodable {
    let productName: String?
    let productNameIt: String?
    let brands: String?
    let categoriesTags: [String]?
    let imageURL: String?
    let imageFrontURL: String?
    let allergensTags: [String]?
    let nutriments: OpenFoodFactsNutrimentsDTO?

    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case productNameIt = "product_name_it"
        case brands
        case categoriesTags = "categories_tags"
        case imageURL = "image_url"
        case imageFrontURL = "image_front_url"
        case allergensTags = "allergens_tags"
        case nutriments
    }
}

struct OpenFoodFactsNutrimentsDTO: Decodable {
    let energyKcal100g: Double?
    let proteins100g: Double?
    let carbohydrates100g: Double?
    let fat100g: Double?
    let sugars100g: Double?
    let salt100g: Double?

    enum CodingKeys: String, CodingKey {
        case energyKcal100g = "energy-kcal_100g"
        case proteins100g = "proteins_100g"
        case carbohydrates100g = "carbohydrates_100g"
        case fat100g = "fat_100g"
        case sugars100g = "sugars_100g"
        case salt100g = "salt_100g"
    }
}
