import Foundation

@MainActor
final class MealPlannerViewModel: ObservableObject {
    @Published private(set) var plan: MealPlan?
    @Published private(set) var isGenerating = false
    @Published var planType: MealPlanType = .threeDays
    @Published var errorMessage: String?

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
            errorMessage = (error as? FoodMapError)?.errorDescription ?? error.localizedDescription
        }
    }

    func createShoppingList() async {
        guard let plan else { return }
        let items = generateShoppingList(plan: plan)
        guard !items.isEmpty else { return }
        do {
            try await shoppingListRepository.add(items)
        } catch {
            errorMessage = (error as? FoodMapError)?.errorDescription ?? error.localizedDescription
        }
    }
}
