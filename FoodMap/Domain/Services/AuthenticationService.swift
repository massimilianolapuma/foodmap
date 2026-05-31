import Foundation

/// Manages the app's authenticated session.
///
/// Sign-in is optional and never sends identity to a third party — the Apple
/// user identifier is only stored locally (Keychain) to keep the user signed in
/// across launches. Domain stays unaware of how the session is persisted.
public protocol AuthenticationService: Sendable {
    /// The persisted session, if any, restored from secure storage.
    func currentUser() async -> AuthenticatedUser?

    /// Completes a Sign in with Apple authorization and persists the session.
    @discardableResult
    func signIn(with credential: AppleSignInCredential) async throws -> AuthenticatedUser

    /// Starts (or continues) an account-less local session.
    @discardableResult
    func continueWithoutAccount() async -> AuthenticatedUser

    /// Clears the persisted session.
    func signOut() async
}

/// Secure, abstracted storage for the authenticated session.
///
/// Implemented by a Keychain-backed store in production and an in-memory store
/// in tests, so the authentication service can be exercised without the Keychain.
public protocol CredentialStore: Sendable {
    func load() throws -> AuthenticatedUser?
    func save(_ user: AuthenticatedUser) throws
    func clear() throws
}
