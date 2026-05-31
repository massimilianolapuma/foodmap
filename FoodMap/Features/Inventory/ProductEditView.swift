import SwiftUI

/// Edit a pantry product: rename, change brand/category, move location,
/// adjust quantity/unit, set or clear the expiry date, or delete it.
struct ProductEditView: View {
    @EnvironmentObject private var container: AppContainer
    let product: Product
    @State private var model: ProductEditViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let model {
                    EditForm(model: model)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Edit Product")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            if model == nil {
                model = ProductEditViewModel(
                    product: product,
                    update: container.updateProduct,
                    repository: container.productRepository
                )
            }
        }
    }
}

private struct EditForm: View {
    @ObservedObject var model: ProductEditViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false

    var body: some View {
        Form {
            Section("Details") {
                TextField("Name", text: $model.name)
                TextField("Brand", text: $model.brand)
                Picker("Category", selection: $model.category) {
                    ForEach(ProductCategory.allCases, id: \.self) { category in
                        Text(category.displayName).tag(category)
                    }
                }
            }

            Section("Storage") {
                Picker("Location", selection: $model.storageLocation) {
                    ForEach(StorageLocation.allCases, id: \.self) { location in
                        Text(location.displayName).tag(location)
                    }
                }
            }

            if let suggestion = model.freezerSuggestion {
                Section("Freezing") {
                    Text(suggestion.advice)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button {
                        model.applyFreezerSuggestion()
                    } label: {
                        Label(
                            "Use estimated freezer date (\(suggestion.suggestedExpiry.formatted(date: .abbreviated, time: .omitted)))",
                            systemImage: "snowflake"
                        )
                    }
                }
            }

            Section("Photo") {
                PhotoCaptureField(imageData: $model.imageData)
            }

            Section("Quantity") {
                Stepper(value: $model.quantity, in: 0...9999, step: 1) {
                    Text("\(model.quantity.formatted()) \(model.unit.abbreviation)")
                }
                Picker("Unit", selection: $model.unit) {
                    ForEach(MeasurementUnit.allCases, id: \.self) { unit in
                        Text(unit.abbreviation).tag(unit)
                    }
                }
            }

            Section("Expiry") {
                Toggle("Has expiry date", isOn: $model.hasExpiry)
                if model.hasExpiry {
                    DatePicker("Expires", selection: $model.expiryDate, displayedComponents: .date)
                }
            }

            Section {
                Button("Delete Product", role: .destructive) {
                    showDeleteConfirmation = true
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task { await model.save() }
                }
                .disabled(!model.canSave || model.isBusy)
            }
        }
        .confirmationDialog(
            "Delete this product?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                Task { await model.delete() }
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Couldn't save", isPresented: failureBinding) {
            Button("OK", role: .cancel) { model.clearFailure() }
        } message: {
            Text(failureMessage)
        }
        .onChange(of: model.outcome) { _, outcome in
            switch outcome {
            case .saved, .deleted:
                dismiss()
            case .none, .failed:
                break
            }
        }
    }

    private var failureMessage: String {
        if case let .failed(message) = model.outcome { return message }
        return ""
    }

    private var failureBinding: Binding<Bool> {
        Binding(
            get: { if case .failed = model.outcome { true } else { false } },
            set: { presented in if !presented { model.clearFailure() } }
        )
    }
}
