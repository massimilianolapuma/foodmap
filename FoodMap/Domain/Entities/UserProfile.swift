import Foundation
import SwiftData

/// The user's preferences and sensitive dietary profile. Stays on device.
@Model
public final class UserProfile {
    @Attribute(.unique) public var id: UUID
    public var displayName: String
    public var dietTypeRaw: String
    public var allergensRaw: [String]
    public var preferredCuisinesRaw: [String]
    public var dailyCalorieTarget: Int?
    public var dailyProteinTargetGrams: Int?
    public var expiryAlertLeadDays: Int
    public var alertsEnabled: Bool
    public var householdSize: Int

    public init(
        id: UUID = UUID(),
        displayName: String = "",
        dietType: DietType = .standard,
        allergens: [Allergen] = [],
        preferredCuisines: [CuisineType] = [.any],
        dailyCalorieTarget: Int? = nil,
        dailyProteinTargetGrams: Int? = nil,
        expiryAlertLeadDays: Int = 3,
        alertsEnabled: Bool = true,
        householdSize: Int = 1
    ) {
        self.id = id
        self.displayName = displayName
        dietTypeRaw = dietType.rawValue
        allergensRaw = allergens.map(\.rawValue)
        preferredCuisinesRaw = preferredCuisines.map(\.rawValue)
        self.dailyCalorieTarget = dailyCalorieTarget
        self.dailyProteinTargetGrams = dailyProteinTargetGrams
        self.expiryAlertLeadDays = expiryAlertLeadDays
        self.alertsEnabled = alertsEnabled
        self.householdSize = householdSize
    }
}

public extension UserProfile {
    /// Maximum number of characters retained for a user-supplied display name.
    static let maxDisplayNameLength = 64

    /// Normalizes a raw display-name input: strips control/newline characters and
    /// caps the length. Internal spaces are preserved so names can be typed naturally;
    /// callers should trim leading/trailing whitespace when presenting the value.
    static func sanitizedDisplayName(_ raw: String) -> String {
        let withoutControl = raw.unicodeScalars.filter { scalar in
            !CharacterSet.controlCharacters.contains(scalar) && !CharacterSet.newlines.contains(scalar)
        }
        let cleaned = String(String.UnicodeScalarView(withoutControl))
        return String(cleaned.prefix(maxDisplayNameLength))
    }

    var dietType: DietType {
        get { DietType(rawValue: dietTypeRaw) ?? .standard }
        set { dietTypeRaw = newValue.rawValue }
    }

    var allergens: [Allergen] {
        get { allergensRaw.compactMap(Allergen.init(rawValue:)) }
        set { allergensRaw = newValue.map(\.rawValue) }
    }

    var preferredCuisines: [CuisineType] {
        get { preferredCuisinesRaw.compactMap(CuisineType.init(rawValue:)) }
        set { preferredCuisinesRaw = newValue.map(\.rawValue) }
    }
}
