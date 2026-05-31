import SwiftUI

/// A single representative image for a product, resolved on-device with this priority:
///
/// 1. The user's captured photo (`imageData`), if present.
/// 2. The official Open Food Facts photo (`imageURLString`), fetched + cached over HTTPS.
/// 3. A category-based SF Symbol icon generated locally (graceful placeholder).
///
/// The category icon also serves as the placeholder shown while the remote photo loads
/// or if it fails, so a product always has a visible representation.
struct ProductImageView: View {
    let id: String
    let imageData: Data?
    let imageURLString: String?
    let category: ProductCategory
    let size: CGFloat

    var body: some View {
        content
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.2))
    }

    @ViewBuilder
    private var content: some View {
        if let imageData {
            ThumbnailImage(id: id, data: imageData, size: size)
        } else if let imageURLString, !imageURLString.isEmpty {
            RemoteImage(urlString: imageURLString, size: size) { placeholder }
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        CategoryIcon(category: category, size: size)
    }
}

/// Tinted rounded tile displaying the category's SF Symbol. Used as the universal
/// fallback / loading placeholder for a product image.
struct CategoryIcon: View {
    let category: ProductCategory
    let size: CGFloat

    var body: some View {
        DesignSystem.Colors.secondaryBackground
            .overlay {
                Image(systemName: category.iconName)
                    .font(.system(size: size * 0.5))
                    .foregroundStyle(DesignSystem.Colors.accent)
            }
    }
}
