import Foundation
import Vision

/// On-device expiry-date OCR using the Vision framework. No data leaves the device.
public struct VisionExpiryOCRService: ExpiryOCRService {
    private let parser: ExpiryDateParser

    public init(parser: ExpiryDateParser = ExpiryDateParser()) {
        self.parser = parser
    }

    public func recognizeExpiryDates(in imageData: Data) async throws -> [Date] {
        let recognizedText = try await recognizeText(in: imageData)
        return parser.parseDates(from: recognizedText)
    }

    private func recognizeText(in imageData: Data) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if error != nil {
                    continuation.resume(throwing: FoodMapError.ocrFailed)
                    return
                }
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let text = observations
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n")
                continuation.resume(returning: text)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false
            request.recognitionLanguages = ["it-IT", "en-US"]

            let handler = VNImageRequestHandler(data: imageData, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: FoodMapError.ocrFailed)
            }
        }
    }
}
