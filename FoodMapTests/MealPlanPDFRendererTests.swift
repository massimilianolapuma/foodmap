import XCTest
@testable import FoodMap

final class MealPlanPDFRendererTests: XCTestCase {
    private func makePlan(mealCount: Int) -> MealPlan {
        let meals = (0..<mealCount).map { index in
            Meal(
                name: "Recipe \(index)",
                mealType: .dinner,
                dayIndex: index,
                recipeSummary: "A tasty dish number \(index)",
                estimatedCalories: 500 + index,
                steps: ["Prep", "Cook", "Serve"],
                prepMinutes: 10,
                cookMinutes: 20,
                ingredients: [
                    MealIngredient(name: "Pasta", quantity: 200, unit: .gram),
                    MealIngredient(name: "Egg", quantity: 2, unit: .piece)
                ]
            )
        }
        return MealPlan(title: "Weekly plan", planType: .week, meals: meals)
    }

    func testRenderProducesValidPDFData() {
        let data = MealPlanPDFRenderer.render(makePlan(mealCount: 3))
        XCTAssertFalse(data.isEmpty)
        let header = String(bytes: data.prefix(5), encoding: .ascii)
        XCTAssertEqual(header, "%PDF-")
    }

    func testRenderEmptyPlanStillProducesPDF() {
        let data = MealPlanPDFRenderer.render(makePlan(mealCount: 0))
        XCTAssertFalse(data.isEmpty)
        XCTAssertEqual(String(bytes: data.prefix(5), encoding: .ascii), "%PDF-")
    }

    func testRenderLargePlanPaginates() {
        let small = MealPlanPDFRenderer.render(makePlan(mealCount: 1))
        let large = MealPlanPDFRenderer.render(makePlan(mealCount: 30))
        XCTAssertGreaterThan(large.count, small.count)
    }
}
