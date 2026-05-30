import Foundation

/// Drives the shopping list screen: loads items from the repository, groups them
/// by grocery category, and routes every mutation (add, toggle, delete, clear)
/// through the `ShoppingListRepository` so the screen stays testable.
@MainActor
final class ShoppingListViewModel: ObservableObject {
    @Published private(set) var items: [ShoppingListItem] = []
    @Published var errorMessage: String?

    // Manual-add form state.
    @Published var newName = ""
    @Published var newQuantity: Double = 1
    @Published var newUnit: MeasurementUnit = .piece
    @Published var newCategory: GroceryCategory = .other

    private let repository: ShoppingListRepository

    init(repository: ShoppingListRepository) {
        self.repository = repository
    }

    /// Sections ordered by `GroceryCategory.allCases`, with unchecked items first
    /// and checked items sunk to the bottom; both groups sorted by name.
    var sections: [(category: GroceryCategory, items: [ShoppingListItem])] {
        GroceryCategory.allCases.compactMap { category in
            let inCategory = items
                .filter { $0.category == category }
                .sorted { lhs, rhs in
                    if lhs.isChecked != rhs.isChecked { return !lhs.isChecked }
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
            return inCategory.isEmpty ? nil : (category, inCategory)
        }
    }

    var isEmpty: Bool {
        items.isEmpty
    }

    var hasCheckedItems: Bool {
        items.contains(where: \.isChecked)
    }

    func load() async {
        do {
            items = try await repository.fetchAll()
        } catch {
            errorMessage = message(for: error)
        }
    }

    /// Validates and persists a manually entered item. Returns `true` on success.
    @discardableResult
    func addManualItem() async -> Bool {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = FoodMapError.invalidInput(reason: "Enter a name for the item.").errorDescription
            return false
        }
        guard newQuantity > 0 else {
            errorMessage = FoodMapError.invalidInput(reason: "Quantity must be greater than zero.").errorDescription
            return false
        }
        let item = ShoppingListItem(
            name: trimmed,
            quantity: newQuantity,
            unit: newUnit,
            category: newCategory
        )
        do {
            try await repository.add([item])
            resetForm()
            await load()
            return true
        } catch {
            errorMessage = message(for: error)
            return false
        }
    }

    func toggleChecked(_ item: ShoppingListItem) async {
        item.isChecked.toggle()
        do {
            try await repository.update(item)
            await load()
        } catch {
            item.isChecked.toggle()
            errorMessage = message(for: error)
        }
    }

    func delete(_ item: ShoppingListItem) async {
        do {
            try await repository.delete(id: item.id)
            await load()
        } catch {
            errorMessage = message(for: error)
        }
    }

    func clearPurchased() async {
        do {
            try await repository.clearChecked()
            await load()
        } catch {
            errorMessage = message(for: error)
        }
    }

    func clearAll() async {
        do {
            for item in items {
                try await repository.delete(id: item.id)
            }
            await load()
        } catch {
            errorMessage = message(for: error)
        }
    }

    private func resetForm() {
        newName = ""
        newQuantity = 1
        newUnit = .piece
        newCategory = .other
    }

    private func message(for error: Error) -> String {
        (error as? FoodMapError)?.errorDescription ?? error.localizedDescription
    }
}
