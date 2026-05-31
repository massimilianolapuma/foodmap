import Foundation

/// Default `AuthenticationService` implementation.
///
/// Persists the session through an injected `CredentialStore` (Keychain in
/// production, in-memory in tests). The Apple authorization itself is driven by
/// the presentation layer (`SignInWithAppleButton`); this service only records
/// the resulting identity and manages the local/anonymous fallback.
public actor AppleAuthenticationService: AuthenticationService {
    private let store: CredentialStore

    public init(store: CredentialStore) {
        self.store = store
    }

    public func currentUser() async -> AuthenticatedUser? {
        try? store.load()
    }

    @discardableResult
    public func signIn(with credential: AppleSignInCredential) async throws -> AuthenticatedUser {
        guard !credential.userID.isEmpty else {
            throw FoodMapError.authenticationFailed(reason: "Missing Apple user identifier.")
        }
        let user = AuthenticatedUser(
            id: credential.userID,
            displayName: credential.fullName,
            email: credential.email,
            isAnonymous: false
        )
        try store.save(user)
        return user
    }

    @discardableResult
    public func continueWithoutAccount() async -> AuthenticatedUser {
        let user = AuthenticatedUser.anonymous
        try? store.save(user)
        return user
    }

    public func signOut() async {
        try? store.clear()
    }
}
