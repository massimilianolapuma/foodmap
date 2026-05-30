import SwiftUI

/// Top-level tab navigation for FoodMap.
struct RootView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Today", systemImage: "calendar") }
                .accessibilityIdentifier("tab.dashboard")

            InventoryView()
                .tabItem { Label("Pantry", systemImage: "shippingbox") }
                .accessibilityIdentifier("tab.inventory")

            ScannerView()
                .tabItem { Label("Scan", systemImage: "barcode.viewfinder") }
                .accessibilityIdentifier("tab.scanner")

            MealPlannerView()
                .tabItem { Label("Meals", systemImage: "fork.knife") }
                .accessibilityIdentifier("tab.meals")

            ShoppingListView()
                .tabItem { Label("Shopping", systemImage: "cart") }
                .accessibilityIdentifier("tab.shopping")

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                .accessibilityIdentifier("tab.profile")
        }
        .tint(DesignSystem.Colors.accent)
    }
}

#Preview {
    RootView()
        .environmentObject(AppContainer(inMemory: true))
}
