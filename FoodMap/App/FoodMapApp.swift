import SwiftData
import SwiftUI

@main
struct FoodMapApp: App {
    @StateObject private var container = AppContainer(inMemory: AppContainer.isUITesting)

    var body: some Scene {
        WindowGroup {
            AuthGateView(model: container.authViewModel) {
                RootView()
            }
            .environmentObject(container)
            .modelContainer(container.modelContainer)
            .task { container.seedUITestDataIfNeeded() }
        }
    }
}
