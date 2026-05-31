import Foundation

/// The engine the user prefers for generating meal plans and suggestions.
///
/// Privacy-first: every option runs on-device. `automatic` picks the best
/// available engine for the current device, preferring the on-device model.
public enum MealPlannerModel: String, Codable, CaseIterable, Sendable {
    /// Best available engine for the device (on-device model when ready,
    /// deterministic rules otherwise).
    case automatic
    /// Deterministic, offline rule-based planner.
    case ruleBased
    /// Apple's on-device FoundationModels engine (iOS 26+).
    case onDevice

    public var displayName: String {
        switch self {
        case .automatic: String(localized: "Automatic")
        case .ruleBased: String(localized: "Rule-based")
        case .onDevice: String(localized: "On-device AI")
        }
    }

    public var detail: String {
        switch self {
        case .automatic: String(localized: "Picks the best engine for this device.")
        case .ruleBased: String(localized: "Fast, deterministic, fully offline.")
        case .onDevice: String(localized: "Apple on-device model. Stays private.")
        }
    }
}
