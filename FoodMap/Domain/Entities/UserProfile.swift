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
        self.householdSize = householdSize
    }
}

public extension UserProfile {
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
