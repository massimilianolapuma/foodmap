import SwiftData
import SwiftUI

/// "Today" dashboard surfacing products that need to be used soon.
/// Reads inventory via SwiftData `@Query`; expiry logic stays in the pure use case.
struct DashboardView: View {
    @Query(sort: \Product.expiryDate, order: .forward) private var products: [Product]
    @Query(sort: \UserProfile.id) private var profiles: [UserProfile]
    private let expiryCalculator = CalculateExpiryStatusUseCase()

    private var greetingName: String {
        profiles.first?.displayName.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private var expiring: [Product] {
        products
            .filter { product in
                guard let days = expiryCalculator.daysRemaining(for: product) else { return false }
                return days <= 7
            }
            .sorted { expiryCalculator.priorityScore(for: $0) > expiryCalculator.priorityScore(for: $1) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if expiring.isEmpty {
                    ContentUnavailableView(
                        "Nothing expiring soon",
                        systemImage: "checkmark.seal",
                        description: Text("Scan products to start tracking expiry dates.")
                    )
                    .accessibilityIdentifier("dashboard.emptyState")
                } else {
                    List(expiring) { product in
                        ExpiringRow(
                            product: product,
                            status: expiryCalculator.status(for: product),
                            days: expiryCalculator.daysRemaining(for: product)
                        )
                    }
                    .accessibilityIdentifier("dashboard.list")
                }
            }
            .navigationTitle("Today")
            .safeAreaInset(edge: .top) {
                if !greetingName.isEmpty {
                    HStack {
                        Text("Hi, \(greetingName)")
                            .font(DesignSystem.Typography.headline)
                            .foregroundStyle(DesignSystem.Colors.secondaryText)
                        Spacer()
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.vertical, DesignSystem.Spacing.xs)
                    .accessibilityIdentifier("dashboard.greeting")
                }
            }
        }
    }
}

private struct ExpiringRow: View {
    let product: Product
    let status: ExpiryStatus
    let days: Int?

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Circle()
                .fill(status.color)
                .frame(width: 12, height: 12)
                .accessibilityHidden(true)
            VStack(alignment: .leading) {
                Text(product.name).font(DesignSystem.Typography.headline)
                Text(product.storageLocation.displayName)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.secondaryText)
            }
            Spacer()
            if let days {
                Text(days < 0 ? "Expired" : "\(days)d")
                    .font(.subheadline.bold())
                    .foregroundStyle(status.color)
            }
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        var parts = [product.name, product.storageLocation.displayName, status.accessibilityDescription]
        if let days {
            parts.append(days < 0 ? "Expired" : "\(days) days remaining")
        }
        return parts.joined(separator: ", ")
    }
}
