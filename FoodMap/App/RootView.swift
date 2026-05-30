import SwiftUI

/// Top-level tab navigation for FoodMap.
struct RootView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Today", systemImage: "calendar") }

            InventoryView()
                .tabItem { Label("Pantry", systemImage: "shippingbox") }

            ScannerView()
                .tabItem { Label("Scan", systemImage: "barcode.viewfinder") }

            MealPlannerView()
                .tabItem { Label("Meals", systemImage: "fork.knife") }

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
        }
        .tint(DesignSystem.Colors.accent)
    }
}

#Preview {
    RootView()
        .environmentObject(AppContainer(inMemory: true))
}
