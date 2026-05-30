import Foundation

@MainActor
final class ScannerViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case looking
        case found(name: String)
        case failed(String)
    }

    @Published var barcode = ""
    @Published var storageLocation: StorageLocation = .fridge
    @Published var quantity: Double = 1
    @Published var unit: MeasurementUnit = .piece
    @Published var hasExpiry = false
    @Published var expiryDate = Date()
    @Published private(set) var state: State = .idle

    /// Drives the live-camera scanning sheet.
    @Published var isScanning = false
    /// Drives the camera-permission-denied alert.
    @Published var permissionDenied = false
    /// The looked-up product awaiting user confirmation before being added.
    @Published var pendingProduct: ProductLookupResult?

    private let lookup: ProductLookupService
    private let addProduct: AddScannedProductToInventoryUseCase
    private let scanner: BarcodeScannerService

    init(
        lookup: ProductLookupService,
        addProduct: AddScannedProductToInventoryUseCase,
        scanner: BarcodeScannerService
    ) {
        self.lookup = lookup
        self.addProduct = addProduct
        self.scanner = scanner
    }

    /// Starts the camera, shows the scanning sheet, and processes the first barcode found.
    func beginScan() async {
        state = .idle
        do {
            try await scanner.start()
            isScanning = true
            for await code in scanner.scannedBarcodes() {
                await finishScan(with: code)
                break
            }
        } catch let error as FoodMapError where error == .cameraPermissionDenied {
            isScanning = false
            permissionDenied = true
        } catch let error as FoodMapError {
            isScanning = false
            state = .failed(error.errorDescription ?? "Scanning failed.")
        } catch {
            isScanning = false
            state = .failed(error.localizedDescription)
        }
    }

    /// Stops the camera and dismisses the scanning sheet without looking anything up.
    func cancelScan() async {
        await scanner.stop()
        isScanning = false
    }

    /// Looks up the manually entered barcode.
    func lookupManual() async {
        await performLookup(barcode: barcode)
    }

    /// Confirms the pending product and adds it to the inventory.
    func confirmAdd() async {
        guard let result = pendingProduct else { return }
        state = .looking
        do {
            try await addProduct(
                lookup: result,
                storageLocation: storageLocation,
                quantity: quantity,
                unit: unit,
                expiryDate: hasExpiry ? expiryDate : nil
            )
            state = .found(name: result.name)
            pendingProduct = nil
            barcode = ""
            resetDetails()
        } catch let error as FoodMapError {
            state = .failed(error.errorDescription ?? "Couldn't add the product.")
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    /// Dismisses the confirmation sheet without adding anything.
    func cancelConfirmation() {
        pendingProduct = nil
        state = .idle
    }

    private func finishScan(with code: String) async {
        await scanner.stop()
        isScanning = false
        barcode = code
        await performLookup(barcode: code)
    }

    private func performLookup(barcode raw: String) async {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            state = .failed("Enter a barcode first.")
            return
        }
        state = .looking
        do {
            let result = try await lookup.fetchProduct(by: trimmed)
            pendingProduct = result
            state = .idle
        } catch let error as FoodMapError {
            state = .failed(error.errorDescription ?? "Lookup failed.")
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    private func resetDetails() {
        quantity = 1
        hasExpiry = false
        expiryDate = Date()
    }
}
