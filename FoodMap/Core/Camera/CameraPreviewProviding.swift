import AVFoundation

/// Surfaces an `AVCaptureSession` for live camera preview in the Presentation layer.
///
/// Defined outside Domain so the domain stays free of AVFoundation. The Data-layer
/// scanner conforms to this so the composition root can vend a preview surface to
/// SwiftUI without exposing concrete capture types to view models.
public protocol CameraPreviewProviding: AnyObject {
    var previewSession: AVCaptureSession { get }
}
