import XCTest
@testable import FoodMap

final class AppleAuthenticationServiceTests: XCTestCase {
    func testSignInPersistsAppleIdentity() async throws {
        let store = InMemoryCredentialStore()
        let service = AppleAuthenticationService(store: store)

        let user = try await service.signIn(
            with: AppleSignInCredential(userID: "apple-123", fullName: "Ada Lovelace", email: "ada@example.com")
        )

        XCTAssertEqual(user.id, "apple-123")
        XCTAssertEqual(user.displayName, "Ada Lovelace")
        XCTAssertEqual(user.email, "ada@example.com")
        XCTAssertFalse(user.isAnonymous)

        let restored = await service.currentUser()
        XCTAssertEqual(restored, user)
    }

    func testSignInWithEmptyUserIDThrows() async {
        let service = AppleAuthenticationService(store: InMemoryCredentialStore())
        do {
            _ = try await service.signIn(with: AppleSignInCredential(userID: ""))
            XCTFail("Expected authentication failure")
        } catch {
            XCTAssertEqual(error as? FoodMapError, .authenticationFailed(reason: "Missing Apple user identifier."))
        }
    }

    func testContinueWithoutAccountStartsAnonymousSession() async {
        let store = InMemoryCredentialStore()
        let service = AppleAuthenticationService(store: store)

        let user = await service.continueWithoutAccount()

        XCTAssertTrue(user.isAnonymous)
        let restored = await service.currentUser()
        XCTAssertEqual(restored, .anonymous)
    }

    func testSignOutClearsSession() async {
        let store = InMemoryCredentialStore(seed: .anonymous)
        let service = AppleAuthenticationService(store: store)

        await service.signOut()

        let restored = await service.currentUser()
        XCTAssertNil(restored)
    }

    func testCurrentUserRestoresSeededSession() async {
        let seeded = AuthenticatedUser(id: "apple-9", displayName: "Grace", email: nil)
        let service = AppleAuthenticationService(store: InMemoryCredentialStore(seed: seeded))

        let restored = await service.currentUser()

        XCTAssertEqual(restored, seeded)
    }
}
