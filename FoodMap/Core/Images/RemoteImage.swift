import SwiftUI
import UIKit

/// Loads a remote product image (e.g. the official Open Food Facts photo) over HTTPS,
/// downsamples it off the main actor, and caches the decoded result locally so it is
/// fetched at most once per size. While loading or on failure the supplied placeholder
/// (typically a category icon) is shown.
///
/// Only the product's own public OFF photo is fetched here — never any sensitive
/// user data — and only over HTTPS, honoring App Transport Security.
struct RemoteImage<Placeholder: View>: View {
    let urlString: String
    let size: CGFloat
    @ViewBuilder var placeholder: () -> Placeholder

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder()
            }
        }
        .task(id: "\(urlString)-\(size)") {
            let scale = UIScreen.main.scale
            image = await RemoteImageLoader.shared.image(for: urlString, maxPixel: size * scale)
        }
    }
}

/// Off-main-actor remote image cache. Downloads bounded image data over HTTPS, decodes
/// a downsampled thumbnail via `ImageDownsampler`, and keeps results in an `NSCache`.
actor RemoteImageLoader {
    static let shared = RemoteImageLoader()

    private let cache = NSCache<NSString, UIImage>()
    private let session: URLSession

    /// Hard cap on a single image download to avoid decoding unbounded payloads.
    private static let maxBytes = 8 * 1024 * 1024

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Returns a secure `URL` only when `string` is a valid absolute HTTPS URL.
    static func secureURL(from string: String) -> URL? {
        guard let url = URL(string: string),
              url.scheme?.lowercased() == "https",
              url.host?.isEmpty == false
        else {
            return nil
        }
        return url
    }

    func image(for urlString: String, maxPixel: CGFloat) async -> UIImage? {
        let key = "\(urlString)-\(Int(maxPixel))" as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }
        guard let url = Self.secureURL(from: urlString) else {
            return nil
        }
        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse,
                  (200..<300).contains(http.statusCode),
                  data.count <= Self.maxBytes,
                  let image = ImageDownsampler.downsample(data: data, maxPixel: maxPixel)
            else {
                return nil
            }
            cache.setObject(image, forKey: key)
            return image
        } catch {
            return nil
        }
    }
}
