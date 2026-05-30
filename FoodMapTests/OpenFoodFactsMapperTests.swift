import XCTest
@testable import FoodMap

final class OpenFoodFactsMapperTests: XCTestCase {
    func testMapsProductFields() throws {
        let dto = OpenFoodFactsResponseDTO(
            status: 1,
            code: "123",
            product: OpenFoodFactsProductDTO(
                productName: "Spaghetti",
                productNameIt: "Spaghetti",
                brands: "Barilla, Other",
                categoriesTags: ["en:pasta"],
                imageURL: "https://img/x.jpg",
                imageFrontURL: "https://img/front.jpg",
                allergensTags: ["en:gluten"],
                nutriments: OpenFoodFactsNutrimentsDTO(
                    energyKcal100g: 350,
                    proteins100g: 12,
                    carbohydrates100g: 70,
                    fat100g: 2,
                    sugars100g: 3,
                    salt100g: 0.1
                )
            )
        )

        let result = try OpenFoodFactsMapper.map(dto, barcode: "123")
        XCTAssertEqual(result.name, "Spaghetti")
        XCTAssertEqual(result.brand, "Barilla")
        XCTAssertEqual(result.allergens, [.gluten])
        XCTAssertEqual(result.imageURLString, "https://img/front.jpg")
        XCTAssertEqual(result.nutrition?.energyKcal, 350)
        XCTAssertEqual(result.source, .openFoodFacts)
    }

    func testThrowsWhenStatusZero() {
        let dto = OpenFoodFactsResponseDTO(status: 0, code: nil, product: nil)
        XCTAssertThrowsError(try OpenFoodFactsMapper.map(dto, barcode: "999")) { error in
            XCTAssertEqual(error as? FoodMapError, .productNotFound(barcode: "999"))
        }
    }
}
