import SwiftData
import XCTest
@testable import FoodMap

final class UserProfileTests: XCTestCase {
    func testDisplayNameDefaultsToEmpty() {
        let profile = UserProfile()
        XCTAssertEqual(profile.displayName, "")
    }

    @MainActor
    func testDisplayNamePersistsInStore() throws {
        let container = try ModelContainer(
            for: UserProfile.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let profile = UserProfile()
        profile.displayName = "Marco"
        context.insert(profile)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<UserProfile>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.displayName, "Marco")
    }

    func testSanitizedDisplayNamePreservesInternalSpaces() {
        XCTAssertEqual(UserProfile.sanitizedDisplayName("Marco Rossi"), "Marco Rossi")
    }

    func testSanitizedDisplayNameStripsControlAndNewlineCharacters() {
        XCTAssertEqual(UserProfile.sanitizedDisplayName("Marco\nRossi\t"), "MarcoRossi")
    }

    func testSanitizedDisplayNameCapsLength() {
        let raw = String(repeating: "a", count: UserProfile.maxDisplayNameLength + 20)
        XCTAssertEqual(
            UserProfile.sanitizedDisplayName(raw).count,
            UserProfile.maxDisplayNameLength
        )
    }
}
