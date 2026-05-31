import SwiftUI

/// Gates the app's main content behind the first-launch onboarding screen.
/// Once completed, the flag persists and onboarding is never shown again
/// (unless reset via the `-resetOnboarding` launch argument).
struct OnboardingGateView<Content: View>: View {
    @AppStorage(OnboardingState.storageKey) private var hasCompletedOnboarding = false
    @ViewBuilder let content: () -> Content

    var body: some View {
        if hasCompletedOnboarding {
            content()
        } else {
            OnboardingView { hasCompletedOnboarding = true }
                .transition(.opacity)
        }
    }
}
