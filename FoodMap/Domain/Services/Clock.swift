import Foundation

/// Abstraction over the current time to keep date logic deterministic in tests.
public protocol Clock: Sendable {
    func now() -> Date
}

public struct SystemClock: Clock {
    public init() {}
    public func now() -> Date {
        Date()
    }
}
