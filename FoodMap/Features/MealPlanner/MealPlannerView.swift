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
                        NavigationLink {
                            MealDetailView(meal: meal)
                        } label: {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                Text(meal.name).font(DesignSystem.Typography.headline)
                                Text("Day \(meal.dayIndex + 1) · \(meal.mealType.displayName)")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundStyle(DesignSystem.Colors.secondaryText)
                                if !meal.recipeSummary.isEmpty {
                                    Text(meal.recipeSummary).font(DesignSystem.Typography.subheadline)
                                }
                                if let detail = previewDetail(for: meal) {
                                    Text(detail)
                                        .font(DesignSystem.Typography.caption)
                                        .foregroundStyle(DesignSystem.Colors.secondaryText)
                                }
                            }
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                .accessibilityIdentifier("meals.list")
                Button("Add missing items to shopping list") {
                    Task { await model.createShoppingList() }
                }
                .padding()
                .disabled(model.isAddingToShopping)
                .accessibilityIdentifier("meals.addToShoppingButton")
                .accessibilityHint("Adds ingredients not in your pantry to the shopping list")
            } else {
                ContentUnavailableView(
                    "No plan yet",
                    systemImage: "fork.knife",
                    description: Text("Generate a plan that uses your expiring products first.")
                )
                .accessibilityIdentifier("meals.emptyState")
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
            .accessibilityIdentifier("meals.generateButton")
            .accessibilityLabel(model.isGenerating ? "Generating plan" : "Generate plan")
            .accessibilityHint("Creates a meal plan that prioritizes products expiring soon")
        }
        .alert(
            "Shopping list",
            isPresented: Binding(
                get: { model.shoppingConfirmation != nil },
                set: { if !$0 { model.shoppingConfirmation = nil } }
            ),
            presenting: model.shoppingConfirmation
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
    }

    private func previewDetail(for meal: Meal) -> String? {
        var parts: [String] = []
        if let minutes = meal.totalMinutes {
            parts.append(String(localized: "\(minutes) min"))
        }
        if let kcal = meal.estimatedCalories {
            parts.append(String(localized: "\(kcal) kcal"))
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}
