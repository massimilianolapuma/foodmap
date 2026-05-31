import CoreTransferable
import UniformTypeIdentifiers
#if canImport(UIKit)
    import UIKit
#endif

/// A shareable PDF document rendered from a ``MealPlan``.
///
/// Wraps the already-rendered PDF bytes so that `ShareLink` can export it via
/// the system share sheet (which surfaces `UIActivityViewController`).
struct MealPlanPDF: Transferable {
    let data: Data
    let filename: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .pdf) { document in
            document.data
        }
        .suggestedFileName { $0.filename }
    }
}

/// Renders a ``MealPlan`` and its recipes to a paginated, localized PDF.
///
/// Pure presentation helper: takes a plan and produces PDF bytes using
/// `UIGraphicsPDFRenderer`. No persistence or networking.
enum MealPlanPDFRenderer {
    #if canImport(UIKit)
        /// A4 page size in PostScript points (72 dpi).
        private static let pageSize = CGSize(width: 595.2, height: 841.8)
        private static let margin: CGFloat = 48
        private static let lineGap: CGFloat = 6

        /// Renders the plan to PDF bytes. Returns an empty document (header only)
        /// when the plan has no meals.
        static func render(_ plan: MealPlan) -> Data {
            let format = UIGraphicsPDFRendererFormat()
            format.documentInfo = [
                kCGPDFContextTitle as String: plan.title,
                kCGPDFContextCreator as String: "FoodMap"
            ]
            let bounds = CGRect(origin: .zero, size: pageSize)
            let renderer = UIGraphicsPDFRenderer(bounds: bounds, format: format)

            return renderer.pdfData { context in
                var layout = Layout(context: context, bounds: bounds)
                layout.beginPage()
                layout.draw(plan.title, font: .boldSystemFont(ofSize: 24))
                layout.draw(planSubtitle(plan), font: .systemFont(ofSize: 12), color: .gray)
                layout.spacer(12)

                let meals = plan.meals.sorted { $0.dayIndex < $1.dayIndex }
                for meal in meals {
                    draw(meal: meal, into: &layout)
                }
            }
        }

        private static func draw(meal: Meal, into layout: inout Layout) {
            layout.ensureSpace(for: 80)
            layout.spacer(8)
            layout.draw(meal.name, font: .boldSystemFont(ofSize: 16))
            layout.draw(mealMeta(meal), font: .systemFont(ofSize: 11), color: .gray)

            if !meal.recipeSummary.isEmpty {
                layout.spacer(2)
                layout.draw(meal.recipeSummary, font: .systemFont(ofSize: 12))
            }

            if !meal.ingredients.isEmpty {
                layout.spacer(4)
                layout.draw(String(localized: "Ingredients"), font: .boldSystemFont(ofSize: 12))
                for ingredient in meal.ingredients {
                    layout.draw("• \(ingredientLabel(ingredient))", font: .systemFont(ofSize: 11))
                }
            }

            if !meal.steps.isEmpty {
                layout.spacer(4)
                layout.draw(String(localized: "Steps"), font: .boldSystemFont(ofSize: 12))
                for (index, step) in meal.steps.enumerated() {
                    layout.draw("\(index + 1). \(step)", font: .systemFont(ofSize: 11))
                }
            }
        }

        private static func planSubtitle(_ plan: MealPlan) -> String {
            let date = plan.startDate.formatted(date: .abbreviated, time: .omitted)
            return String(localized: "Starting \(date)")
        }

        private static func mealMeta(_ meal: Meal) -> String {
            var parts: [String] = [
                String(localized: "Day \(meal.dayIndex + 1)"),
                meal.mealType.displayName
            ]
            if let minutes = meal.totalMinutes {
                parts.append(String(localized: "\(minutes) min"))
            }
            if let kcal = meal.estimatedCalories {
                parts.append(String(localized: "\(kcal) kcal"))
            }
            return parts.joined(separator: " · ")
        }

        private static func ingredientLabel(_ ingredient: MealIngredient) -> String {
            let quantity = ingredient.quantity
            let amount = quantity == quantity.rounded()
                ? String(Int(quantity))
                : String(format: "%.1f", quantity)
            return "\(ingredient.name) — \(amount) \(ingredient.unit.abbreviation)"
        }

        /// Mutable cursor that draws text top-to-bottom and paginates as needed.
        private struct Layout {
            let context: UIGraphicsPDFRendererContext
            let bounds: CGRect
            var cursorY: CGFloat = 0

            mutating func beginPage() {
                context.beginPage()
                cursorY = margin
            }

            mutating func ensureSpace(for height: CGFloat) {
                if cursorY + height > bounds.height - margin {
                    beginPage()
                }
            }

            mutating func spacer(_ height: CGFloat) {
                cursorY += height
            }

            mutating func draw(_ text: String, font: UIFont, color: UIColor = .black) {
                let maxWidth = bounds.width - margin * 2
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: color
                ]
                let attributed = NSAttributedString(string: text, attributes: attributes)
                let boundingRect = attributed.boundingRect(
                    with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    context: nil
                )
                let height = ceil(boundingRect.height)
                ensureSpace(for: height)
                attributed.draw(in: CGRect(x: margin, y: cursorY, width: maxWidth, height: height))
                cursorY += height + lineGap
            }
        }
    #endif
}
