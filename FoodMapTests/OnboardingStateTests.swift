import XCTest
@testable import FoodMap

final class OnboardingStateTests: XCTestCase {
    private let suiteName = "OnboardingStateTests"
    private lazy var defaults = UserDefaults(suiteName: suiteName) ?? .standard

    override func setUp() {
        super.setUp()
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func testResetArgumentClearsCompletion() {
        defaults.set(true, forKey: OnboardingState.storageKey)

        OnboardingState.configure(arguments: ["app", "-resetOnboarding"], defaults: defaults)

        XCTAssertFalse(defaults.bool(forKey: OnboardingState.storageKey))
    }

    func testUITestingSkipsOnboardingByDefault() {
        OnboardingState.configure(arguments: ["app", "-uiTesting"], defaults: defaults)

        XCTAssertTrue(defaults.bool(forKey: OnboardingState.storageKey))
    }

    func testUITestingWithShowOnboardingDoesNotSkip() {
        OnboardingState.configure(arguments: ["app", "-uiTesting", "-showOnboarding"], defaults: defaults)

        XCTAssertFalse(defaults.bool(forKey: OnboardingState.storageKey))
    }

    func testNormalLaunchLeavesFlagUntouched() {
        OnboardingState.configure(arguments: ["app"], defaults: defaults)

        XCTAssertNil(defaults.object(forKey: OnboardingState.storageKey))
    }
}
