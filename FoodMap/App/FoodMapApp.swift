import SwiftData
import SwiftUI

@main
struct FoodMapApp: App {
    @StateObject private var container = AppContainer()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(container)
                .modelContainer(container.modelContainer)
        }
    }
}
