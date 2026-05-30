import AVFoundation
import SwiftUI

/// SwiftUI wrapper around an `AVCaptureVideoPreviewLayer` bound to a capture session.
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context _: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context _: Context) {
        uiView.videoPreviewLayer.session = session
    }

    /// A `UIView` whose backing layer is an `AVCaptureVideoPreviewLayer`.
    final class PreviewView: UIView {
        override static var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }

        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            // swiftlint:disable:next force_cast
            layer as! AVCaptureVideoPreviewLayer
        }
    }
}
