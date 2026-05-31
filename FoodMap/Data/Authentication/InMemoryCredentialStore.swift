import Foundation

/// In-memory `CredentialStore` for tests and UI-testing runs, avoiding any
/// Keychain access. Thread-safe so it can be shared across the app's actors.
public final class InMemoryCredentialStore: CredentialStore, @unchecked Sendable {
    private let lock = NSLock()
    private var user: AuthenticatedUser?

    public init(seed: AuthenticatedUser? = nil) {
        user = seed
    }

    public func load() throws -> AuthenticatedUser? {
        lock.lock()
        defer { lock.unlock() }
        return user
    }

    public func save(_ user: AuthenticatedUser) throws {
        lock.lock()
        defer { lock.unlock() }
        self.user = user
    }

    public func clear() throws {
        lock.lock()
        defer { lock.unlock() }
        user = nil
    }
}
