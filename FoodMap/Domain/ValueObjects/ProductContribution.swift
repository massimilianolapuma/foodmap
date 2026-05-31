import Foundation

/// Credentials for a user's own Open Food Facts account.
///
/// Each user contributes with their personal OFF account — there is no shared
/// app-wide account. Credentials are never embedded in source and should be
/// stored securely (Keychain) by the presentation/data layer.
public struct OpenFoodFactsCredentials: Equatable, Sendable {
    public let username: String
    public let password: String

    public init(username: String, password: String) {
        self.username = username
        self.password = password
    }

    /// True when both fields are non-empty after trimming whitespace.
    public var isComplete: Bool {
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

/// A new product the user chooses to contribute to the Open Food Facts database
/// when a barcode is not found. Contributing is always opt-in and never required.
///
/// Only public product metadata travels to Open Food Facts — never the user's
/// allergies, diet, or nutrition targets.
public struct ProductContribution: Equatable, Sendable {
    public let barcode: String
    public let name: String
    public let brand: String?
    public let categories: String?
    public let quantity: String?

    public init(
        barcode: String,
        name: String,
        brand: String? = nil,
        categories: String? = nil,
        quantity: String? = nil
    ) {
        self.barcode = barcode
        self.name = name
        self.brand = brand
        self.categories = categories
        self.quantity = quantity
    }
}
