import SwiftData
import SwiftUI

/// Pantry inventory grouped by storage location, sorted by expiry, with
/// per-location filtering and tap-to-edit.
struct InventoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Product.name) private var products: [Product]
    private let expiryCalculator = CalculateExpiryStatusUseCase()

    /// `nil` means "All locations".
    @State private var filter: StorageLocation?
    @State private var selectedProduct: Product?
    @State private var isScanning = false

    var body: some View {
        NavigationStack {
            Group {
                if products.isEmpty {
                    ContentUnavailableView(
                        "Your pantry is empty",
                        systemImage: "shippingbox",
                        description: Text("Scan or add products to track them here.")
                    )
                    .accessibilityIdentifier("inventory.emptyState")
                } else {
                    VStack(spacing: 0) {
                        filterPicker
                        content
                    }
                }
            }
            .navigationTitle("Pantry")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isScanning = true
                    } label: {
                        Label("Scan", systemImage: "barcode.viewfinder")
                    }
                    .accessibilityIdentifier("inventory.scanButton")
                }
            }
            .sheet(item: $selectedProduct) { product in
                ProductEditView(product: product)
            }
            .sheet(isPresented: $isScanning) {
                ScannerView()
            }
        }
    }

    private var filterPicker: some View {
        Picker("Filter", selection: $filter) {
            Text("All").tag(StorageLocation?.none)
            ForEach(StorageLocation.allCases, id: \.self) { location in
                Text(location.displayName).tag(StorageLocation?.some(location))
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.top, DesignSystem.Spacing.sm)
        .accessibilityIdentifier("inventory.filter")
    }

    @ViewBuilder
    private var content: some View {
        if let filter, items(in: filter).isEmpty {
            ContentUnavailableView(
                "Nothing in \(filter.displayName)",
                systemImage: "tray",
                description: Text("Move or add products to your \(filter.displayName.lowercased()).")
            )
            .accessibilityIdentifier("inventory.filteredEmptyState")
        } else {
            List {
                ForEach(visibleLocations, id: \.self) { location in
                    let items = items(in: location)
                    if !items.isEmpty {
                        Section(location.displayName) {
                            ForEach(items) { product in
                                Button {
                                    selectedProduct = product
                                } label: {
                                    InventoryRow(product: product, status: expiryCalculator.status(for: product))
                                }
                                .buttonStyle(.plain)
                            }
                            .onDelete { offsets in
                                delete(items: items, at: offsets)
                            }
                        }
                    }
                }
            }
            .accessibilityIdentifier("inventory.list")
        }
    }

    private var visibleLocations: [StorageLocation] {
        if let filter { return [filter] }
        return StorageLocation.allCases
    }

    private func items(in location: StorageLocation) -> [Product] {
        products
            .filter { $0.storageLocation == location }
            .sorted(by: Self.byExpiry)
    }

    /// Soonest-to-expire first; products without an expiry date sort last.
    private static func byExpiry(_ lhs: Product, _ rhs: Product) -> Bool {
        switch (lhs.expiryDate, rhs.expiryDate) {
        case let (left?, right?): left < right
        case (_?, nil): true
        case (nil, _?): false
        case (nil, nil): lhs.name < rhs.name
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
            Circle()
                .fill(status.color)
                .frame(width: 10, height: 10)
                .accessibilityHidden(true)
            VStack(alignment: .leading) {
                Text(product.name).font(DesignSystem.Typography.headline)
                if let brand = product.brand {
                    Text(brand)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.secondaryText)
                }
            }
            Spacer()
            Text("\(product.quantity.formatted()) \(product.unit.abbreviation)")
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.Colors.secondaryText)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Double tap to edit")
    }

    private var accessibilityLabel: String {
        var parts = [product.name]
        if let brand = product.brand { parts.append(brand) }
        parts.append("\(product.quantity.formatted()) \(product.unit.abbreviation)")
        parts.append(status.accessibilityDescription)
        return parts.joined(separator: ", ")
    }
}
