import AVFoundation
import SwiftUI

/// Scan or manually enter a barcode, look it up, confirm details, and add it to the pantry.
struct ScannerView: View {
    @EnvironmentObject private var container: AppContainer
    @Environment(\.dismiss) private var dismiss
    @State private var model: ScannerViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let model {
                    ScannerForm(model: model, previewSession: container.cameraPreviewProvider.previewSession)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Scan")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .accessibilityIdentifier("scanner.doneButton")
                }
            }
        }
        .task {
            if model == nil {
                model = ScannerViewModel(
                    lookup: container.productLookup,
                    addProduct: container.addScannedProduct,
                    scanner: container.barcodeScanner,
                    expiryOCR: container.expiryOCR
                )
            }
        }
    }
}

private struct ScannerForm: View {
    @ObservedObject var model: ScannerViewModel
    let previewSession: AVCaptureSession

    private var confirmationBinding: Binding<Bool> {
        Binding(
            get: { model.pendingProduct != nil },
            set: { presented in if !presented { model.cancelConfirmation() } }
        )
    }

    var body: some View {
        Form {
            Section("Barcode") {
                TextField("Enter barcode", text: $model.barcode)
                    .keyboardType(.numberPad)
                    .accessibilityIdentifier("scanner.barcodeField")
                Button("Scan with camera") {
                    Task { await model.beginScan() }
                }
                .accessibilityIdentifier("scanner.scanButton")
                .accessibilityHint("Opens the camera to scan a product barcode")
                Button("Look up") {
                    Task { await model.lookupManual() }
                }
                .disabled(model.barcode.trimmingCharacters(in: .whitespaces).isEmpty)
                .accessibilityIdentifier("scanner.lookupButton")
                .accessibilityHint("Looks up the entered barcode in the product database")
            }

            Section {
                statusView
            }
        }
        .fullScreenCover(isPresented: $model.isScanning) {
            ScanningView(session: previewSession) {
                Task { await model.cancelScan() }
            }
        }
        .sheet(isPresented: confirmationBinding) {
            if let product = model.pendingProduct {
                ConfirmationSheet(model: model, product: product)
            }
        }
        .alert("Camera access needed", isPresented: $model.permissionDenied) {
            Button("Open Settings") { openSettings() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enable camera access in Settings to scan product barcodes.")
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
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

/// Full-screen live camera preview with a framing guide and a cancel control.
private struct ScanningView: View {
    let session: AVCaptureSession
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            CameraPreviewView(session: session)
                .ignoresSafeArea()

            Color.black.opacity(0.25)
                .ignoresSafeArea()

            RoundedRectangle(cornerRadius: 16)
                .stroke(.white, lineWidth: 3)
                .frame(width: 260, height: 160)
                .shadow(radius: 8)

            VStack {
                Spacer()
                Text("Point the camera at a barcode")
                    .font(DesignSystem.Typography.callout)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                Button("Cancel", action: onCancel)
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
            }
        }
        .accessibilityElement(children: .contain)
    }
}

/// Confirms a looked-up product's storage details before adding it to the pantry.
private struct ConfirmationSheet: View {
    @ObservedObject var model: ScannerViewModel
    let product: ProductLookupResult

    var body: some View {
        NavigationStack {
            Form {
                Section("Product") {
                    Text(product.name)
                        .font(DesignSystem.Typography.headline)
                    if let brand = product.brand, !brand.isEmpty {
                        Text(brand)
                            .foregroundStyle(DesignSystem.Colors.secondaryText)
                    }
                    Text(product.barcode)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.secondaryText)
                        .accessibilityLabel("Barcode \(product.barcode)")
                }

                Section("Details") {
                    Picker("Location", selection: $model.storageLocation) {
                        ForEach(StorageLocation.allCases, id: \.self) { Text($0.displayName).tag($0) }
                    }
                    Stepper("Quantity: \(model.quantity.formatted())", value: $model.quantity, in: 1...99)
                    Picker("Unit", selection: $model.unit) {
                        ForEach(MeasurementUnit.allCases, id: \.self) { Text($0.abbreviation).tag($0) }
                    }
                }

                expirySection
            }
            .navigationTitle("Add product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { model.cancelConfirmation() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { Task { await model.confirmAdd() } }
                }
            }
            .sheet(isPresented: $model.isCapturingExpiry) {
                ImagePicker(sourceType: .camera) { data in
                    Task { await model.recognizeExpiry(from: data) }
                }
                .ignoresSafeArea()
            }
            .alert("Camera access needed", isPresented: $model.permissionDenied) {
                Button("Open Settings") { openSettings() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Enable camera access in Settings to scan expiry dates.")
            }
        }
    }

    private var expirySection: some View {
        Section("Expiry") {
            Button {
                requestExpiryCapture()
            } label: {
                Label("Scan expiry date", systemImage: "text.viewfinder")
            }

            if model.isRecognizingExpiry {
                HStack {
                    ProgressView()
                    Text("Reading date\u{2026}")
                        .foregroundStyle(.secondary)
                }
            }

            if !model.expiryCandidates.isEmpty {
                ForEach(model.expiryCandidates, id: \.self) { date in
                    Button {
                        model.selectExpiryCandidate(date)
                    } label: {
                        Label(
                            date.formatted(date: .abbreviated, time: .omitted),
                            systemImage: isSelected(date) ? "checkmark.circle.fill" : "calendar"
                        )
                    }
                }
            }

            if model.noExpiryDetected {
                Text("No date detected \u{2014} enter manually")
                    .foregroundStyle(.secondary)
            }

            Toggle("Has expiry date", isOn: $model.hasExpiry)
            if model.hasExpiry {
                DatePicker("Expires", selection: $model.expiryDate, displayedComponents: .date)
            }
        }
    }

    private func isSelected(_ date: Date) -> Bool {
        model.hasExpiry && model.expiryDate == date
    }

    private func requestExpiryCapture() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            model.isCapturingExpiry = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                Task { @MainActor in
                    if granted {
                        model.isCapturingExpiry = true
                    } else {
                        model.permissionDenied = true
                    }
                }
            }
        default:
            model.permissionDenied = true
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
