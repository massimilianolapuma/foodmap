import SwiftUI
import UIKit

/// A reusable, skippable photo field. Shows the current product photo (if any) and
/// lets the user capture a new one with the camera or pick from the photo library, or
/// remove it. The result is stored as JPEG `Data` on-device only — never uploaded.
struct PhotoCaptureField: View {
    @Binding var imageData: Data?

    @State private var pickerSource: PickerSource?
    @State private var showSourceDialog = false

    private var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            if let imageData, let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .accessibilityLabel("Product photo")
                    .accessibilityIdentifier("product.photo.preview")
            }

            HStack {
                Button {
                    showSourceDialog = true
                } label: {
                    Label(
                        imageData == nil ? "Add Photo" : "Replace Photo",
                        systemImage: "camera"
                    )
                }
                .accessibilityIdentifier("product.photo.addButton")

                if imageData != nil {
                    Spacer()
                    Button(role: .destructive) {
                        imageData = nil
                    } label: {
                        Label("Remove Photo", systemImage: "trash")
                    }
                    .accessibilityIdentifier("product.photo.removeButton")
                }
            }
        }
        .confirmationDialog("Add a photo", isPresented: $showSourceDialog, titleVisibility: .visible) {
            if isCameraAvailable {
                Button("Take Photo") { pickerSource = PickerSource(type: .camera) }
            }
            Button("Choose from Library") { pickerSource = PickerSource(type: .photoLibrary) }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(item: $pickerSource) { source in
            ImagePicker(sourceType: source.type) { data in
                imageData = data
            }
            .ignoresSafeArea()
        }
    }
}

/// Identifiable wrapper so the picker can be presented via `.sheet(item:)`.
private struct PickerSource: Identifiable {
    let id = UUID()
    let type: UIImagePickerController.SourceType
}
