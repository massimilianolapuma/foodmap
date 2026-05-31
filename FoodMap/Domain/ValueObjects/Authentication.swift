import Foundation

/// An authenticated identity for the app session.
///
/// Sign-in is optional: the user can continue without an Apple account, in which
/// case an `anonymous` user is used so the app stays fully usable offline. When
/// the user signs in with Apple, `id` is the stable Apple user identifier.
public struct AuthenticatedUser: Sendable, Equatable, Codable {
    public let id: String
    public let displayName: String?
    public let email: String?
    public let isAnonymous: Bool

    public init(id: String, displayName: String? = nil, email: String? = nil, isAnonymous: Bool = false) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.isAnonymous = isAnonymous
    }

    /// A local, account-less session. Used when the user chooses to continue
    /// without signing in. No identity is shared with any third party.
    public static let anonymous = AuthenticatedUser(
        id: "local-anonymous",
        displayName: nil,
        email: nil,
        isAnonymous: true
    )
}

/// The fields extracted from a successful Sign in with Apple authorization.
///
/// Lives in Domain so the authentication service stays framework-agnostic; the
/// presentation layer maps `ASAuthorizationAppleIDCredential` onto this type.
public struct AppleSignInCredential: Sendable, Equatable {
    public let userID: String
    public let fullName: String?
    public let email: String?

    public init(userID: String, fullName: String? = nil, email: String? = nil) {
        self.userID = userID
        self.fullName = fullName
        self.email = email
    }
}
