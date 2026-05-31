import Foundation

/// Drives the sign-in gate. Restores any persisted session, completes a Sign in
/// with Apple authorization, and supports continuing without an account. Depends
/// only on the Domain `AuthenticationService`.
@MainActor
final class AuthViewModel: ObservableObject {
    @Published private(set) var user: AuthenticatedUser?
    @Published private(set) var isRestoring = true
    @Published var errorMessage: String?

    private let service: AuthenticationService

    init(service: AuthenticationService) {
        self.service = service
    }

    var isAuthenticated: Bool {
        user != nil
    }

    /// Loads any persisted session on launch.
    func restore() async {
        user = await service.currentUser()
        isRestoring = false
    }

    /// Records a successful Sign in with Apple authorization.
    func completeSignIn(with credential: AppleSignInCredential) async {
        do {
            user = try await service.signIn(with: credential)
            errorMessage = nil
        } catch {
            errorMessage = (error as? FoodMapError)?.errorDescription ?? error.localizedDescription
        }
    }

    /// Surfaces a Sign in with Apple failure (ignores user-initiated cancel).
    func handleSignInFailure(_ error: FoodMapError) {
        guard error != .authenticationCancelled else { return }
        errorMessage = error.errorDescription
    }

    /// Starts an account-less local session so the app stays usable offline.
    func continueWithoutAccount() async {
        user = await service.continueWithoutAccount()
        errorMessage = nil
    }

    /// Clears the session and returns to the sign-in gate.
    func signOut() async {
        await service.signOut()
        user = nil
    }
}
