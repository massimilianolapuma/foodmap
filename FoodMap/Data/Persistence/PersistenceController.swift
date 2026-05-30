import Foundation
import SwiftData

/// Builds the SwiftData `ModelContainer` for the app, with an in-memory option for tests.
public enum PersistenceController {
    public static let schema = Schema([
        Product.self,
        NutritionInfo.self,
        UserProfile.self,
        MealPlan.self,
        Meal.self,
        MealIngredient.self,
        ShoppingListItem.self
    ])

    public static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            throw FoodMapError.persistence(reason: error.localizedDescription)
        }
    }
}
