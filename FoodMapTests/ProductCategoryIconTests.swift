import XCTest
@testable import FoodMap

final class ProductCategoryIconTests: XCTestCase {
    func testEveryCategoryHasNonEmptyIcon() {
        for category in ProductCategory.allCases {
            XCTAssertFalse(category.iconName.isEmpty, "\(category) should have an icon")
        }
    }

    func testIconNamesAreUnique() {
        let names = ProductCategory.allCases.map(\.iconName)
        XCTAssertEqual(Set(names).count, names.count, "Each category should map to a distinct icon")
    }

    func testKnownMappings() {
        XCTAssertEqual(ProductCategory.fruitsVegetables.iconName, "carrot.fill")
        XCTAssertEqual(ProductCategory.frozen.iconName, "snowflake")
        XCTAssertEqual(ProductCategory.other.iconName, "bag.fill")
    }
}
