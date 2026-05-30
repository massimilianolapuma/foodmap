import Foundation

/// Typed, user-presentable errors surfaced across layers.
public enum FoodMapError: LocalizedError, Equatable, Sendable {
    case productNotFound(barcode: String)
    case network(reason: String)
    case decoding(reason: String)
    case persistence(reason: String)
    case scannerUnavailable
    case cameraPermissionDenied
    case ocrFailed
    case notificationPermissionDenied
    case invalidInput(reason: String)

    public var errorDescription: String? {
        switch self {
        case let .productNotFound(barcode):
            "No product found for barcode \(barcode). You can add it manually."
        case let .network(reason):
            "Network problem: \(reason)"
        case let .decoding(reason):
            "Couldn't read the response: \(reason)"
        case let .persistence(reason):
            "Couldn't save your data: \(reason)"
        case .scannerUnavailable:
            "The barcode scanner isn't available on this device."
        case .cameraPermissionDenied:
            "Camera access is needed to scan products. Enable it in Settings."
        case .ocrFailed:
            "Couldn't read the expiry date. Try again or enter it manually."
        case .notificationPermissionDenied:
            "Notifications are off. Enable them to get expiry alerts."
        case let .invalidInput(reason):
            reason
        }
    }
}
