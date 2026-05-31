import Foundation

@MainActor
final class MealPlannerViewModel: ObservableObject {
    @Published private(set) var plan: MealPlan?
    @Published private(set) var isGenerating = false
    @Published private(set) var isAddingToShopping = false
    @Published var planType: MealPlanType = .threeDays
    @Published var errorMessage: String?
    /// User-facing confirmation after adding missing items to the shopping list.
    @Published var shoppingConfirmation: String?

    private let planner: MealPlannerAIService
    private let generateShoppingList: GenerateShoppingListFromMealPlanUseCase
    private let mealPlanRepository: MealPlanRepository
    private let shoppingListRepository: ShoppingListRepository

    init(
        planner: MealPlannerAIService,
        generateShoppingList: GenerateShoppingListFromMealPlanUseCase,
        mealPlanRepository: MealPlanRepository,
        shoppingListRepository: ShoppingListRepository
    ) {
        self.planner = planner
        self.generateShoppingList = generateShoppingList
        self.mealPlanRepository = mealPlanRepository
        self.shoppingListRepository = shoppingListRepository
    }

    func generate(products: [Product], profile: UserProfile) async {
        isGenerating = true
        defer { isGenerating = false }
        do {
            let newPlan = try await planner.generatePlan(from: products, profile: profile, planType: planType)
            try await mealPlanRepository.save(newPlan)
            plan = newPlan
        } catch {
            errorMessage = message(for: error)
        }
    }

    /// Adds the plan's missing ingredients to the shopping list, merging into any
    /// items already present (same name + unit) instead of creating duplicates,
    /// then surfaces a confirmation so the user knows the tap took effect.
    func createShoppingList() async {
        guard let plan else { return }
        let generated = generateShoppingList(plan: plan)
        guard !generated.isEmpty else {
            shoppingConfirmation = "All ingredients are already in your pantry."
            return
        }
        isAddingToShopping = true
        defer { isAddingToShopping = false }
        do {
            shoppingConfirmation = try await merge(generated)
        } catch {
            errorMessage = message(for: error)
        }
    }

    /// Merges `generated` items into the existing shopping list and returns a
    /// human-readable summary of what was added vs. updated.
    private func merge(_ generated: [ShoppingListItem]) async throws -> String {
        let existing = try await shoppingListRepository.fetchAll()
        var existingByKey = Dictionary(
            existing.map { (Self.mergeKey(for: $0), $0) },
            uniquingKeysWith: { current, _ in current }
        )
        var toInsert: [ShoppingListItem] = []
        var updatedCount = 0
        for item in generated {
            let key = Self.mergeKey(for: item)
            if let match = existingByKey[key] {
                match.quantity += item.quantity
                try await shoppingListRepository.update(match)
                updatedCount += 1
            } else {
                toInsert.append(item)
                existingByKey[key] = item
            }
        }
        if !toInsert.isEmpty {
            try await shoppingListRepository.add(toInsert)
        }
        return Self.confirmationMessage(added: toInsert.count, updated: updatedCount)
    }

    private static func mergeKey(for item: ShoppingListItem) -> String {
        item.name.lowercased() + "|" + item.unit.rawValue
    }

    private static func confirmationMessage(added: Int, updated: Int) -> String {
        if added > 0, updated > 0 {
            return "Added \(pluralized(added, "item")) and updated \(updated) already on your list."
        }
        if added > 0 {
            return "Added \(pluralized(added, "item")) to your shopping list."
        }
        if updated > 0 {
            return "Updated \(pluralized(updated, "item")) already on your shopping list."
        }
        return "Nothing to add."
    }

    private static func pluralized(_ count: Int, _ noun: String) -> String {
        "\(count) \(noun)\(count == 1 ? "" : "s")"
    }

    private func message(for error: Error) -> String {
        (error as? FoodMapError)?.errorDescription ?? error.localizedDescription
    }
}
