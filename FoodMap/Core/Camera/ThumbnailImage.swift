import SwiftUI
import UIKit

/// Displays a small thumbnail decoded from stored JPEG `Data` without ever decoding
/// the full-resolution image on the main thread. Decoding is downsampled via ImageIO
/// off the main actor and cached, so scrolling a list of product photos stays smooth.
struct ThumbnailImage: View {
    /// Stable identity for the underlying item (used for cache + task identity so we
    /// never compare/hash multi-megabyte `Data` on every body recomputation).
    let id: String
    let data: Data
    let size: CGFloat

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.clear
            }
        }
        .task(id: "\(id)-\(data.count)") {
            let scale = UIScreen.main.scale
            image = await ThumbnailLoader.shared.thumbnail(
                for: data,
                id: id,
                maxPixel: size * scale
            )
        }
    }
}

/// Off-main-actor downsampling cache. Keeps a bounded set of decoded thumbnails so a
/// given photo is only decoded once per row size.
actor ThumbnailLoader {
    static let shared = ThumbnailLoader()

    private let cache = NSCache<NSString, UIImage>()

    func thumbnail(for data: Data, id: String, maxPixel: CGFloat) -> UIImage? {
        let key = "\(id)-\(data.count)-\(Int(maxPixel))" as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }
        guard let image = ImageDownsampler.downsample(data: data, maxPixel: maxPixel) else {
            return nil
        }
        cache.setObject(image, forKey: key)
        return image
    }
}
