import Foundation
import SwiftData

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

    func startScanning() async {
        do {
            try await scanner.start()
            for await code in scanner.scannedBarcodes() {
                barcode = code
                await lookupAndAdd()
                break
            }
        } catch {
            state = .failed((error as? FoodMapError)?.errorDescription ?? error.localizedDescription)
        }
        await scanner.stop()
    }

    func lookupAndAdd() async {
        let trimmed = barcode.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            state = .failed("Enter a barcode first.")
            return
        }
        state = .looking
        do {
            let result = try await lookup.fetchProduct(by: trimmed)
            try await addProduct(
                lookup: result,
                storageLocation: storageLocation,
                quantity: quantity,
                unit: unit,
                expiryDate: hasExpiry ? expiryDate : nil
            )
            state = .found(name: result.name)
            barcode = ""
        } catch let error as FoodMapError {
            state = .failed(error.errorDescription ?? "Lookup failed.")
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
