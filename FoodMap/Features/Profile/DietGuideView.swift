import SwiftUI

/// Informational guide to the supported diet types. Explains each diet's
/// principles and the foods it typically includes or excludes so the user can
/// pick the ones that fit. Informational only — not medical or nutritional
/// advice.
struct DietGuideView: View {
    var body: some View {
        List {
            Section {
                Text("Informational only — not medical or nutritional advice. Adjust your diets anytime in your profile.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            ForEach(DietType.allCases, id: \.self) { diet in
                Section(diet.displayName) {
                    Text(diet.explanation)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("dietGuide.explanation.\(diet.rawValue)")
                }
            }
        }
        .navigationTitle("Diet guide")
        .navigationBarTitleDisplayMode(.inline)
    }
}
