import SwiftUI

/// Full recipe detail for a single meal: ingredients with quantities, estimated
/// calories, prep/cook time, and step-by-step instructions.
struct MealDetailView: View {
    let meal: Meal

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
    }

    private var metaRow: some View {
        HStack(spacing: DesignSystem.Spacing.lg) {
            metaItem(systemImage: "calendar", text: "Day \(meal.dayIndex + 1)")
            metaItem(systemImage: "fork.knife", text: meal.mealType.displayName)
            if let minutes = meal.totalMinutes {
                metaItem(systemImage: "clock", text: "\(minutes) min")
            }
            if let kcal = meal.estimatedCalories {
                metaItem(systemImage: "flame", text: "\(kcal) kcal")
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
