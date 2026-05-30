import SwiftUI

/// Shopping list grouped by grocery category with check-off, manual add, swipe
/// delete, and clear actions. View stays thin; all logic and persistence live in
/// `ShoppingListViewModel`.
struct ShoppingListView: View {
    @EnvironmentObject private var container: AppContainer
    @State private var model: ShoppingListViewModel?
    @State private var isAddingItem = false

    var body: some View {
        NavigationStack {
            Group {
                if let model {
                    content(model: model)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Shopping")
            .toolbar { toolbar }
            .sheet(isPresented: $isAddingItem) {
                if let model {
                    AddShoppingItemView(model: model)
                }
            }
        }
        .task {
            if model == nil {
                model = ShoppingListViewModel(repository: container.shoppingListRepository)
            }
            await model?.load()
        }
        .onAppear {
            Task { await model?.load() }
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                isAddingItem = true
            } label: {
                Label("Add item", systemImage: "plus")
            }
        }
        if let model, !model.isEmpty {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Button("Clear purchased") {
                        Task { await model.clearPurchased() }
                    }
                    .disabled(!model.hasCheckedItems)
                    Button("Clear all", role: .destructive) {
                        Task { await model.clearAll() }
                    }
                } label: {
                    Label("More", systemImage: "ellipsis.circle")
                }
            }
        }
    }

    @ViewBuilder
    private func content(model: ShoppingListViewModel) -> some View {
        if model.isEmpty {
            ContentUnavailableView {
                Label("Nothing to buy", systemImage: "cart")
            } description: {
                Text("Generate a list from a meal plan, or add items manually.")
            } actions: {
                Button("Add item") { isAddingItem = true }
                    .buttonStyle(.borderedProminent)
            }
        } else {
            List {
                ForEach(model.sections, id: \.category) { section in
                    Section(section.category.displayName) {
                        ForEach(section.items) { item in
                            ShoppingItemRow(item: item) {
                                Task { await model.toggleChecked(item) }
                            }
                        }
                        .onDelete { offsets in
                            let toDelete = offsets.map { section.items[$0] }
                            Task {
                                for item in toDelete {
                                    await model.delete(item)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct ShoppingItemRow: View {
    let item: ShoppingListItem
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: DesignSystem.Spacing.md) {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isChecked ? DesignSystem.Colors.accent : .secondary)
                VStack(alignment: .leading) {
                    Text(item.name)
                        .font(.headline)
                        .strikethrough(item.isChecked)
                        .foregroundStyle(item.isChecked ? .secondary : .primary)
                }
                Spacer()
                Text("\(item.quantity.formatted()) \(item.unit.abbreviation)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Sheet that collects a manual shopping-list item and validates it via the model.
private struct AddShoppingItemView: View {
    @ObservedObject var model: ShoppingListViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    TextField("Name", text: $model.newName)
                    Stepper(
                        value: $model.newQuantity,
                        in: 0.5...999,
                        step: 0.5
                    ) {
                        Text("Quantity: \(model.newQuantity.formatted())")
                    }
                    Picker("Unit", selection: $model.newUnit) {
                        ForEach(MeasurementUnit.allCases, id: \.self) { unit in
                            Text(unit.abbreviation).tag(unit)
                        }
                    }
                    Picker("Category", selection: $model.newCategory) {
                        ForEach(GroceryCategory.allCases, id: \.self) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                }
                if let errorMessage = model.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle("Add item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            if await model.addManualItem() { dismiss() }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ShoppingListView()
        .environmentObject(AppContainer(inMemory: true))
}
