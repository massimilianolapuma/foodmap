import SwiftData
import SwiftUI

/// Generates a meal plan prioritizing soon-to-expire products.
struct MealPlannerView: View {
    @EnvironmentObject private var container: AppContainer
    @Query private var products: [Product]
    @Query private var profiles: [UserProfile]
    @State private var model: MealPlannerViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let model {
                    content(model: model)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Meals")
        }
        .task {
            if model == nil {
                model = MealPlannerViewModel(
                    planner: container.mealPlanner,
                    generateShoppingList: container.generateShoppingList,
                    mealPlanRepository: container.mealPlanRepository,
                    shoppingListRepository: container.shoppingListRepository
                )
            }
        }
    }

    private func content(model: MealPlannerViewModel) -> some View {
        VStack(spacing: 0) {
            Picker("Horizon", selection: Binding(get: { model.planType }, set: { model.planType = $0 })) {
                Text("1 day").tag(MealPlanType.singleDay)
                Text("3 days").tag(MealPlanType.threeDays)
                Text("Week").tag(MealPlanType.week)
            }
            .pickerStyle(.segmented)
            .padding()

            if let plan = model.plan {
                List {
                    ForEach(plan.meals.sorted { $0.dayIndex < $1.dayIndex }) { meal in
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text(meal.name).font(.headline)
                            Text("Day \(meal.dayIndex + 1) · \(meal.mealType.displayName)")
                                .font(.caption).foregroundStyle(.secondary)
                            if !meal.recipeSummary.isEmpty {
                                Text(meal.recipeSummary).font(.subheadline)
                            }
                        }
                    }
                }
                Button("Add missing items to shopping list") {
                    Task { await model.createShoppingList() }
                }
                .padding()
            } else {
                ContentUnavailableView(
                    "No plan yet",
                    systemImage: "fork.knife",
                    description: Text("Generate a plan that uses your expiring products first.")
                )
            }

            Button {
                Task { await model.generate(products: products, profile: profiles.first ?? UserProfile()) }
            } label: {
                if model.isGenerating {
                    ProgressView()
                } else {
                    Text("Generate plan").frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
    }
}
