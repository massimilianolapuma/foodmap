import XCTest
@testable import FoodMap

final class DietTypeTests: XCTestCase {
    func testEveryDietHasNonEmptyExplanation() {
        for diet in DietType.allCases {
            XCTAssertFalse(
                diet.explanation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                "Diet \(diet.rawValue) is missing an explanation"
            )
        }
    }

    func testExplanationsAreDistinctPerDiet() {
        let explanations = DietType.allCases.map(\.explanation)
        XCTAssertEqual(Set(explanations).count, DietType.allCases.count)
    }
}
