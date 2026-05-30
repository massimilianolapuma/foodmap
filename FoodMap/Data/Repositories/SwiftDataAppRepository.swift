import Foundation
import SwiftData

/// SwiftData-backed persistence for user profile, meal plans, and shopping list.
@ModelActor
public actor SwiftDataAppRepository: UserProfileRepository, MealPlanRepository, ShoppingListRepository {
    // MARK: UserProfileRepository

    public func load() async throws -> UserProfile? {
        try fetch(FetchDescriptor<UserProfile>()).first
    }

    public func save(_ profile: UserProfile) async throws {
        let id = profile.id
        let existing = try fetch(FetchDescriptor<UserProfile>(predicate: #Predicate { $0.id == id })).first
        if existing == nil {
            modelContext.insert(profile)
        }
        try persist()
    }

    // MARK: MealPlanRepository

    public func save(_ plan: MealPlan) async throws {
        modelContext.insert(plan)
        try persist()
    }

    public func fetchLatest() async throws -> MealPlan? {
        var descriptor = FetchDescriptor<MealPlan>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        descriptor.fetchLimit = 1
        return try fetch(descriptor).first
    }

    public func fetchAll() async throws -> [MealPlan] {
        try fetch(FetchDescriptor<MealPlan>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))
    }

    /// Deletes the entity matching `id`. Satisfies both `MealPlanRepository` and
    /// `ShoppingListRepository`; the unique UUID matches at most one entity of either type.
    public func delete(id: UUID) async throws {
        let plans = try fetch(FetchDescriptor<MealPlan>(predicate: #Predicate { $0.id == id }))
        plans.forEach(modelContext.delete)
        let items = try fetch(FetchDescriptor<ShoppingListItem>(predicate: #Predicate { $0.id == id }))
        items.forEach(modelContext.delete)
        try persist()
    }

    // MARK: ShoppingListRepository

    public func add(_ items: [ShoppingListItem]) async throws {
        items.forEach(modelContext.insert)
        try persist()
    }

    public func fetchAll() async throws -> [ShoppingListItem] {
        try fetch(FetchDescriptor<ShoppingListItem>(sortBy: [SortDescriptor(\.addedAt, order: .reverse)]))
    }

    public func update(_: ShoppingListItem) async throws {
        try persist()
    }

    public func clearChecked() async throws {
        let checked = try fetch(FetchDescriptor<ShoppingListItem>(predicate: #Predicate { $0.isChecked }))
        checked.forEach(modelContext.delete)
        try persist()
    }

    // MARK: Helpers

    private func fetch<T>(_ descriptor: FetchDescriptor<T>) throws -> [T] {
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw FoodMapError.persistence(reason: error.localizedDescription)
        }
    }

    private func persist() throws {
        do {
            try modelContext.save()
        } catch {
            throw FoodMapError.persistence(reason: error.localizedDescription)
        }
    }
}
