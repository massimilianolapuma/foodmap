import SwiftData
import SwiftUI

@main
struct FoodMapApp: App {
    @StateObject private var container = AppContainer(inMemory: AppContainer.isUITesting)

    init() {
        OnboardingState.configure()
    }

    var body: some Scene {
        WindowGroup {
            OnboardingGateView {
                RootView()
            }
            .environmentObject(container)
            .modelContainer(container.modelContainer)
            .task { container.seedUITestDataIfNeeded() }
        }
    }
}
