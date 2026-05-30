import Foundation

/// Persistence operations for pantry products. Implemented in the Data layer.
public protocol ProductRepository: Sendable {
    func add(_ product: Product) async throws
    func update(_ product: Product) async throws
    func delete(id: UUID) async throws
    func fetchAll() async throws -> [Product]
    func fetch(id: UUID) async throws -> Product?
    func fetch(byBarcode barcode: String) async throws -> Product?
    func fetch(in location: StorageLocation) async throws -> [Product]
}

/// Higher-level inventory queries derived from products.
public protocol InventoryRepository: Sendable {
    func expiringProducts(within days: Int) async throws -> [Product]
    func count(in location: StorageLocation) async throws -> Int
}

/// Persistence for generated meal plans.
public protocol MealPlanRepository: Sendable {
    func save(_ plan: MealPlan) async throws
    func fetchLatest() async throws -> MealPlan?
    func fetchAll() async throws -> [MealPlan]
    func delete(id: UUID) async throws
}

/// Persistence for the user's dietary profile.
public protocol UserProfileRepository: Sendable {
    func load() async throws -> UserProfile?
    func save(_ profile: UserProfile) async throws
}

/// Persistence for shopping-list items.
public protocol ShoppingListRepository: Sendable {
    func add(_ items: [ShoppingListItem]) async throws
    func fetchAll() async throws -> [ShoppingListItem]
    func update(_ item: ShoppingListItem) async throws
    func delete(id: UUID) async throws
    func clearChecked() async throws
}
