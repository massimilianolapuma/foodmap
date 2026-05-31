import SwiftUI

/// Full recipe detail for a single meal: ingredients with quantities, estimated
/// calories, prep/cook time, and step-by-step instructions.
struct MealDetailView: View {
    let meal: Meal
    /// When provided, enables swapping this recipe for a similar alternative.
    var viewModel: MealPlannerViewModel?

    @Environment(\.dismiss) private var dismiss
    @State private var showingAlternatives = false
    @State private var shoppingConfirmation: String?

    var body: some View {
        List {
            Section {
                metaRow
                if !meal.recipeSummary.isEmpty {
                    Text(meal.recipeSummary)
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundStyle(DesignSystem.Colors.secondaryText)
                }
            }

            Section("Ingredients") {
                if meal.ingredients.isEmpty {
                    Text("No ingredients yet.")
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundStyle(DesignSystem.Colors.secondaryText)
                } else {
                    ForEach(meal.ingredients) { ingredient in
                        HStack {
                            Image(systemName: ingredient.isAvailableInPantry ? "checkmark.circle.fill" : "cart")
                                .foregroundStyle(
                                    ingredient.isAvailableInPantry
                                        ? DesignSystem.Colors.fresh
                                        : DesignSystem.Colors.secondaryText
                                )
                                .accessibilityHidden(true)
                            Text(ingredient.name)
                                .font(DesignSystem.Typography.body)
                            Spacer()
                            Text(quantityLabel(for: ingredient))
                                .font(DesignSystem.Typography.callout)
                                .foregroundStyle(DesignSystem.Colors.secondaryText)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
            .accessibilityIdentifier("mealDetail.ingredients")

            if let viewModel {
                Section {
                    Button {
                        Task {
                            await viewModel.addMealToShoppingList(meal)
                            shoppingConfirmation = viewModel.shoppingConfirmation
                            viewModel.shoppingConfirmation = nil
                        }
                    } label: {
                        Label("Add to shopping list", systemImage: "cart.badge.plus")
                    }
                    .disabled(viewModel.isAddingToShopping)
                    .accessibilityIdentifier("mealDetail.addToShoppingButton")
                    .accessibilityHint("Adds this recipe's ingredients not in your pantry to the shopping list")
                }
            }

            Section("Steps") {
                if meal.steps.isEmpty {
                    Text("No steps available.")
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundStyle(DesignSystem.Colors.secondaryText)
                } else {
                    ForEach(Array(meal.steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
                            Text("\(index + 1)")
                                .font(DesignSystem.Typography.headline)
                                .foregroundStyle(DesignSystem.Colors.accent)
                                .accessibilityHidden(true)
                            Text(step)
                                .font(DesignSystem.Typography.body)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Step \(index + 1): \(step)")
                    }
                }
            }
            .accessibilityIdentifier("mealDetail.steps")
        }
        .navigationTitle(meal.name)
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("mealDetail.view")
        .toolbar {
            if let viewModel {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Replace") {
                        showingAlternatives = true
                        Task { await viewModel.loadAlternatives(for: meal) }
                    }
                    .accessibilityIdentifier("mealDetail.replaceButton")
                }
            }
        }
        .sheet(isPresented: $showingAlternatives) {
            if let viewModel {
                ReplaceRecipeView(meal: meal, viewModel: viewModel) {
                    showingAlternatives = false
                    dismiss()
                }
            }
        }
        .alert(
            "Shopping list",
            isPresented: Binding(
                get: { shoppingConfirmation != nil },
                set: { if !$0 { shoppingConfirmation = nil } }
            ),
            presenting: shoppingConfirmation
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
    }

    private var metaRow: some View {
        HStack(spacing: DesignSystem.Spacing.lg) {
            metaItem(systemImage: "calendar", text: String(localized: "Day \(meal.dayIndex + 1)"))
            metaItem(systemImage: "fork.knife", text: meal.mealType.displayName)
            if let minutes = meal.totalMinutes {
                metaItem(systemImage: "clock", text: String(localized: "\(minutes) min"))
            }
            if let kcal = meal.estimatedCalories {
                metaItem(systemImage: "flame", text: String(localized: "\(kcal) kcal"))
            }
        }
        .font(DesignSystem.Typography.caption)
        .foregroundStyle(DesignSystem.Colors.secondaryText)
    }

    private func metaItem(systemImage: String, text: String) -> some View {
        Label(text, systemImage: systemImage)
            .labelStyle(.titleAndIcon)
    }

    private func quantityLabel(for ingredient: MealIngredient) -> String {
        let quantity = ingredient.quantity
        let amount = quantity == quantity.rounded()
            ? String(Int(quantity))
            : String(format: "%.1f", quantity)
        return "\(amount) \(ingredient.unit.abbreviation)"
    }
}

/// Sheet offering a few similar recipes the user can pick to replace the current
/// meal. Selecting one swaps it in place while keeping the rest of the plan.
struct ReplaceRecipeView: View {
    let meal: Meal
    @ObservedObject var viewModel: MealPlannerViewModel
    let onReplaced: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoadingAlternatives {
                    ProgressView()
                        .accessibilityIdentifier("replaceRecipe.loading")
                } else if viewModel.alternatives.isEmpty {
                    ContentUnavailableView(
                        "No alternatives",
                        systemImage: "fork.knife",
                        description: Text("Add more products to your pantry to get other recipe ideas.")
                    )
                    .accessibilityIdentifier("replaceRecipe.emptyState")
                } else {
                    List(viewModel.alternatives) { alternative in
                        Button {
                            Task {
                                if await viewModel.replace(meal, with: alternative) {
                                    onReplaced()
                                }
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                Text(alternative.name).font(DesignSystem.Typography.headline)
                                if !alternative.recipeSummary.isEmpty {
                                    Text(alternative.recipeSummary)
                                        .font(DesignSystem.Typography.subheadline)
                                        .foregroundStyle(DesignSystem.Colors.secondaryText)
                                }
                                if let detail = detail(for: alternative) {
                                    Text(detail)
                                        .font(DesignSystem.Typography.caption)
                                        .foregroundStyle(DesignSystem.Colors.secondaryText)
                                }
                            }
                        }
                        .accessibilityElement(children: .combine)
                    }
                    .accessibilityIdentifier("replaceRecipe.list")
                }
            }
            .navigationTitle("Replace recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func detail(for meal: Meal) -> String? {
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
