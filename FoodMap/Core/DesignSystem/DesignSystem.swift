import SwiftUI

/// Centralized design tokens for FoodMap. Owned by the design system; views consume these.
public enum DesignSystem {
    public enum Colors {
        public static let accent = Color.green
        public static let critical = Color.red
        public static let warning = Color.orange
        public static let upcoming = Color.yellow
        public static let fresh = Color.green
        public static let secondaryBackground = Color(.secondarySystemBackground)
    }

    public enum Spacing {
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 16
        public static let lg: CGFloat = 24
        public static let xl: CGFloat = 32
    }

    public enum Radius {
        public static let card: CGFloat = 12
        public static let chip: CGFloat = 8
    }
}

public extension ExpiryStatus {
    /// The design-system color representing this status.
    var color: Color {
        switch self {
        case .expired, .critical: DesignSystem.Colors.critical
        case .soon: DesignSystem.Colors.warning
        case .upcoming: DesignSystem.Colors.upcoming
        case .fresh: DesignSystem.Colors.fresh
        }
    }
}
