import XCTest
@testable import FoodMap

@MainActor
final class AuthViewModelTests: XCTestCase {
    func testRestoreLoadsPersistedSession() async {
        let service = AppleAuthenticationService(store: InMemoryCredentialStore(seed: .anonymous))
        let model = AuthViewModel(service: service)

        XCTAssertTrue(model.isRestoring)
        await model.restore()

        XCTAssertFalse(model.isRestoring)
        XCTAssertTrue(model.isAuthenticated)
    }

    func testRestoreWithNoSessionLeavesUnauthenticated() async {
        let service = AppleAuthenticationService(store: InMemoryCredentialStore())
        let model = AuthViewModel(service: service)

        await model.restore()

        XCTAssertFalse(model.isAuthenticated)
        XCTAssertNil(model.user)
    }

    func testCompleteSignInAuthenticatesAndClearsError() async {
        let service = AppleAuthenticationService(store: InMemoryCredentialStore())
        let model = AuthViewModel(service: service)

        await model.completeSignIn(with: AppleSignInCredential(userID: "apple-1", fullName: "Ada", email: nil))

        XCTAssertTrue(model.isAuthenticated)
        XCTAssertEqual(model.user?.id, "apple-1")
        XCTAssertNil(model.errorMessage)
    }

    func testCompleteSignInWithEmptyIDSurfacesError() async {
        let service = AppleAuthenticationService(store: InMemoryCredentialStore())
        let model = AuthViewModel(service: service)

        await model.completeSignIn(with: AppleSignInCredential(userID: ""))

        XCTAssertFalse(model.isAuthenticated)
        XCTAssertNotNil(model.errorMessage)
    }

    func testCancelledFailureDoesNotSurfaceError() {
        let service = AppleAuthenticationService(store: InMemoryCredentialStore())
        let model = AuthViewModel(service: service)

        model.handleSignInFailure(.authenticationCancelled)

        XCTAssertNil(model.errorMessage)
    }

    func testUnavailableFailureSurfacesGuidance() {
        let service = AppleAuthenticationService(store: InMemoryCredentialStore())
        let model = AuthViewModel(service: service)

        model.handleSignInFailure(.authenticationUnavailable)

        XCTAssertEqual(model.errorMessage, FoodMapError.authenticationUnavailable.errorDescription)
    }

    func testContinueWithoutAccountStartsAnonymousSession() async {
        let service = AppleAuthenticationService(store: InMemoryCredentialStore())
        let model = AuthViewModel(service: service)

        await model.continueWithoutAccount()

        XCTAssertTrue(model.isAuthenticated)
        XCTAssertEqual(model.user, .anonymous)
    }

    func testSignOutReturnsToGate() async {
        let service = AppleAuthenticationService(store: InMemoryCredentialStore(seed: .anonymous))
        let model = AuthViewModel(service: service)
        await model.restore()
        XCTAssertTrue(model.isAuthenticated)

        await model.signOut()

        XCTAssertFalse(model.isAuthenticated)
        XCTAssertNil(model.user)
    }
}
