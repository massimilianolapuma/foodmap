import Foundation
import SwiftData

/// SwiftData-backed implementation of product persistence and inventory queries.
/// Runs on a `ModelActor` to keep SwiftData access isolated and concurrency-safe.
@ModelActor
public actor SwiftDataProductRepository: ProductRepository, InventoryRepository {
    public func add(_ product: Product) async throws {
        modelContext.insert(product)
        try save()
    }

    public func update(_: Product) async throws {
        try save()
    }

    public func delete(id: UUID) async throws {
        let descriptor = FetchDescriptor<Product>(predicate: #Predicate { $0.id == id })
        if let product = try modelContext.fetch(descriptor).first {
            modelContext.delete(product)
            try save()
        }
    }

    public func fetchAll() async throws -> [Product] {
        let descriptor = FetchDescriptor<Product>(sortBy: [SortDescriptor(\.addedDate, order: .reverse)])
        return try fetch(descriptor)
    }

    public func fetch(id: UUID) async throws -> Product? {
        let descriptor = FetchDescriptor<Product>(predicate: #Predicate { $0.id == id })
        return try fetch(descriptor).first
    }

    public func fetch(byBarcode barcode: String) async throws -> Product? {
        let descriptor = FetchDescriptor<Product>(predicate: #Predicate { $0.barcode == barcode })
        return try fetch(descriptor).first
    }

    public func fetch(in location: StorageLocation) async throws -> [Product] {
        let raw = location.rawValue
        let descriptor = FetchDescriptor<Product>(predicate: #Predicate { $0.storageLocationRaw == raw })
        return try fetch(descriptor)
    }

    // MARK: InventoryRepository

    public func expiringProducts(within days: Int) async throws -> [Product] {
        let now = Date()
        guard let limit = Calendar.current.date(byAdding: .day, value: days, to: now) else { return [] }
        let descriptor = FetchDescriptor<Product>(
            predicate: #Predicate { product in
                product.expiryDate.flatMap { $0 <= limit } ?? false
            },
            sortBy: [SortDescriptor(\.expiryDate, order: .forward)]
        )
        return try fetch(descriptor)
    }

    public func count(in location: StorageLocation) async throws -> Int {
        try await fetch(in: location).count
    }

    // MARK: Helpers

    private func fetch<T>(_ descriptor: FetchDescriptor<T>) throws -> [T] {
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw FoodMapError.persistence(reason: error.localizedDescription)
        }
    }

    private func save() throws {
        do {
            try modelContext.save()
        } catch {
            throw FoodMapError.persistence(reason: error.localizedDescription)
        }
    }
}
