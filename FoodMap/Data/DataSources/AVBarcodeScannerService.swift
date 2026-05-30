import AVFoundation
import Foundation

/// Captures barcodes from the rear camera using AVFoundation and emits them as a stream.
public final class AVBarcodeScannerService: NSObject, BarcodeScannerService, @unchecked Sendable {
    public let captureSession = AVCaptureSession()
    private let metadataOutput = AVCaptureMetadataOutput()
    private let sessionQueue = DispatchQueue(label: "com.foodmap.scanner.session")

    private var continuation: AsyncStream<String>.Continuation?
    private let supportedTypes: [AVMetadataObject.ObjectType] = [.ean8, .ean13, .upce, .code128]

    override public init() {
        super.init()
    }

    public func scannedBarcodes() -> AsyncStream<String> {
        AsyncStream { continuation in
            self.continuation = continuation
        }
    }

    public func start() async throws {
        let authorized = await ensureAuthorized()
        guard authorized else { throw FoodMapError.cameraPermissionDenied }

        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            sessionQueue.async {
                do {
                    try self.configureSessionIfNeeded()
                    if !self.captureSession.isRunning {
                        self.captureSession.startRunning()
                    }
                    cont.resume()
                } catch {
                    cont.resume(throwing: error)
                }
            }
        }
    }

    public func stop() async {
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            sessionQueue.async {
                if self.captureSession.isRunning {
                    self.captureSession.stopRunning()
                }
                self.continuation?.finish()
                cont.resume()
            }
        }
    }

    private func ensureAuthorized() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            true
        case .notDetermined:
            await AVCaptureDevice.requestAccess(for: .video)
        default:
            false
        }
    }

    private func configureSessionIfNeeded() throws {
        guard captureSession.inputs.isEmpty else { return }
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              captureSession.canAddInput(input)
        else {
            throw FoodMapError.scannerUnavailable
        }
        captureSession.addInput(input)

        guard captureSession.canAddOutput(metadataOutput) else {
            throw FoodMapError.scannerUnavailable
        }
        captureSession.addOutput(metadataOutput)
        metadataOutput.setMetadataObjectsDelegate(self, queue: sessionQueue)
        metadataOutput.metadataObjectTypes = supportedTypes
    }
}

extension AVBarcodeScannerService: CameraPreviewProviding {
    public var previewSession: AVCaptureSession {
        captureSession
    }
}

extension AVBarcodeScannerService: AVCaptureMetadataOutputObjectsDelegate {
    public func metadataOutput(
        _: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from _: AVCaptureConnection
    ) {
        for object in metadataObjects {
            guard let readable = object as? AVMetadataMachineReadableCodeObject,
                  let value = readable.stringValue else { continue }
            continuation?.yield(value)
        }
    }
}
