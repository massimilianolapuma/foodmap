import SwiftData
import SwiftUI

/// Pantry inventory grouped by storage location.
struct InventoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Product.name) private var products: [Product]
    private let expiryCalculator = CalculateExpiryStatusUseCase()

    var body: some View {
        NavigationStack {
            Group {
                if products.isEmpty {
                    ContentUnavailableView(
                        "Your pantry is empty",
                        systemImage: "shippingbox",
                        description: Text("Scan or add products to track them here.")
                    )
                } else {
                    List {
                        ForEach(StorageLocation.allCases, id: \.self) { location in
                            let items = products.filter { $0.storageLocation == location }
                            if !items.isEmpty {
                                Section(location.displayName) {
                                    ForEach(items) { product in
                                        InventoryRow(product: product, status: expiryCalculator.status(for: product))
                                    }
                                    .onDelete { offsets in
                                        delete(items: items, at: offsets)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Pantry")
        }
    }

    private func delete(items: [Product], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(items[index])
        }
        try? modelContext.save()
    }
}

private struct InventoryRow: View {
    let product: Product
    let status: ExpiryStatus

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Circle().fill(status.color).frame(width: 10, height: 10)
            VStack(alignment: .leading) {
                Text(product.name).font(.headline)
                if let brand = product.brand {
                    Text(brand).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text("\(product.quantity.formatted()) \(product.unit.abbreviation)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
