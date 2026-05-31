import Foundation

/// Owns the persistence key and launch-time configuration for the first-launch
/// onboarding experience. Pure logic so it can be unit-tested without UI.
enum OnboardingState {
    /// `UserDefaults` / `AppStorage` key tracking whether onboarding was completed.
    static let storageKey = "hasCompletedOnboarding"

    /// Applies launch-argument overrides so automated tests can control onboarding.
    ///
    /// - `-resetOnboarding`: force onboarding to show again (clears the flag).
    /// - `-uiTesting` without `-showOnboarding`: skip onboarding so existing UI
    ///   tests land directly on the main tab bar.
    ///
    /// Parameters are injectable to keep this unit-testable.
    static func configure(
        arguments: [String] = ProcessInfo.processInfo.arguments,
        defaults: UserDefaults = .standard
    ) {
        if arguments.contains("-resetOnboarding") {
            defaults.set(false, forKey: storageKey)
            return
        }
        if arguments.contains("-uiTesting"), !arguments.contains("-showOnboarding") {
            defaults.set(true, forKey: storageKey)
        }
    }
}
