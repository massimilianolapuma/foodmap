import SwiftUI

/// Scan or manually enter a barcode, look it up, and add it to the pantry.
struct ScannerView: View {
    @EnvironmentObject private var container: AppContainer
    @State private var model: ScannerViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let model {
                    ScannerForm(model: model)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Scan")
        }
        .task {
            if model == nil {
                model = ScannerViewModel(
                    lookup: container.productLookup,
                    addProduct: container.addScannedProduct,
                    scanner: container.barcodeScanner
                )
            }
        }
    }
}

private struct ScannerForm: View {
    @ObservedObject var model: ScannerViewModel

    var body: some View {
        Form {
            Section("Barcode") {
                TextField("Enter barcode", text: $model.barcode)
                    .keyboardType(.numberPad)
                Button("Scan with camera") {
                    Task { await model.startScanning() }
                }
            }

            Section("Details") {
                Picker("Location", selection: $model.storageLocation) {
                    ForEach(StorageLocation.allCases, id: \.self) { Text($0.displayName).tag($0) }
                }
                Stepper("Quantity: \(model.quantity.formatted())", value: $model.quantity, in: 1...99)
                Picker("Unit", selection: $model.unit) {
                    ForEach(MeasurementUnit.allCases, id: \.self) { Text($0.abbreviation).tag($0) }
                }
                Toggle("Has expiry date", isOn: $model.hasExpiry)
                if model.hasExpiry {
                    DatePicker("Expires", selection: $model.expiryDate, displayedComponents: .date)
                }
            }

            Section {
                Button("Look up & add") {
                    Task { await model.lookupAndAdd() }
                }
                statusView
            }
        }
    }

    @ViewBuilder
    private var statusView: some View {
        switch model.state {
        case .idle:
            EmptyView()
        case .looking:
            ProgressView()
        case let .found(name):
            Label("Added \(name)", systemImage: "checkmark.circle.fill")
                .foregroundStyle(DesignSystem.Colors.accent)
        case let .failed(message):
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(DesignSystem.Colors.critical)
        }
    }
}
