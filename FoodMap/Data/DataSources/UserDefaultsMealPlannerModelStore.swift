import Foundation
#if canImport(FoundationModels)
    import FoundationModels
#endif

/// Persists the user's meal-planner engine choice in `UserDefaults` and reports
/// whether the on-device FoundationModels engine is available on this device.
public final class UserDefaultsMealPlannerModelStore: MealPlannerModelStore {
    private let defaults: UserDefaults
    private let key = "mealPlannerModel"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func selectedModel() -> MealPlannerModel {
        guard let raw = defaults.string(forKey: key),
              let model = MealPlannerModel(rawValue: raw)
        else { return .automatic }
        // Never hand back an engine the device can't run.
        if model == .onDevice, !isOnDeviceModelAvailable() { return .automatic }
        return model
    }

    public func select(_ model: MealPlannerModel) {
        defaults.set(model.rawValue, forKey: key)
    }

    public func isOnDeviceModelAvailable() -> Bool {
        #if canImport(FoundationModels)
            if #available(iOS 26, *) {
                if case .available = SystemLanguageModel.default.availability { return true }
            }
        #endif
        return false
    }
}
