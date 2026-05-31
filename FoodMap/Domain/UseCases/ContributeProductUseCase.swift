import Foundation

/// Contributes a not-found product to Open Food Facts using the user's own account.
///
/// This is an explicit, opt-in action: it runs only when the user chooses to
/// share a manually-added product so future scans resolve for everyone.
public struct ContributeProductToOpenFoodFactsUseCase: Sendable {
    private let service: ProductContributionService

    public init(service: ProductContributionService) {
        self.service = service
    }

    public func callAsFunction(
        _ contribution: ProductContribution,
        using credentials: OpenFoodFactsCredentials
    ) async throws {
        guard credentials.isComplete else {
            throw FoodMapError.invalidInput(reason: "Open Food Facts username and password are required.")
        }
        try await service.contribute(contribution, using: credentials)
    }
}
