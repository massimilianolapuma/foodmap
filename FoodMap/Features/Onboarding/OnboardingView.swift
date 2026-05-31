import SwiftUI

/// A single page in the first-launch onboarding flow.
struct OnboardingPage: Identifiable {
    let id = UUID()
    let systemImage: String
    let title: LocalizedStringKey
    let message: LocalizedStringKey
}

/// First-launch welcome screen introducing FoodMap's core value. Shown once;
/// completion is persisted by ``OnboardingGateView`` via `AppStorage`.
struct OnboardingView: View {
    /// Invoked when the user finishes onboarding.
    let onFinish: () -> Void

    @State private var selection = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            systemImage: "shippingbox.fill",
            title: "Welcome to FoodMap",
            message: "Track what's in your pantry and stop losing food to forgotten expiry dates."
        ),
        OnboardingPage(
            systemImage: "barcode.viewfinder",
            title: "Scan in seconds",
            message: "Scan a barcode to identify products, then capture expiry dates with your camera."
        ),
        OnboardingPage(
            systemImage: "fork.knife",
            title: "Cook smart",
            message: "Get meal plans that use what's expiring first, plus an automatic shopping list."
        )
    ]

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            TabView(selection: $selection) {
                ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                    pageView(page)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button(action: advance) {
                Text(isLastPage ? "Get started" : "Continue")
                    .font(DesignSystem.Typography.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.Spacing.sm)
            }
            .buttonStyle(.borderedProminent)
            .tint(DesignSystem.Colors.accent)
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.bottom, DesignSystem.Spacing.lg)
            .accessibilityIdentifier("onboarding.getStarted")
        }
    }

    private var isLastPage: Bool {
        selection >= pages.count - 1
    }

    private func advance() {
        if isLastPage {
            onFinish()
        } else {
            withAnimation { selection += 1 }
        }
    }

    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Spacer(minLength: 0)
            Image(systemName: page.systemImage)
                .font(.system(size: 72))
                .foregroundStyle(DesignSystem.Colors.accent)
                .accessibilityHidden(true)
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text(page.title)
                    .font(DesignSystem.Typography.titleL)
                    .multilineTextAlignment(.center)
                Text(page.message)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, DesignSystem.Spacing.xl)
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    OnboardingView(onFinish: {})
}
