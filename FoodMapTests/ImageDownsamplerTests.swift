import UIKit
import XCTest
@testable import FoodMap

final class ImageDownsamplerTests: XCTestCase {
    func testDownsamplesLargeImageWithinBounds() throws {
        let large = Self.makeImage(side: 800)
        let data = try XCTUnwrap(large.jpegData(compressionQuality: 0.9))

        let result = ImageDownsampler.downsample(data: data, maxPixel: 80)
        let image = try XCTUnwrap(result)

        XCTAssertLessThanOrEqual(image.size.width * image.scale, 80)
        XCTAssertLessThanOrEqual(image.size.height * image.scale, 80)
    }

    func testReturnsNilForInvalidData() {
        XCTAssertNil(ImageDownsampler.downsample(data: Data([0x00, 0x01, 0x02]), maxPixel: 40))
    }

    private static func makeImage(side: CGFloat) -> UIImage {
        let size = CGSize(width: side, height: side)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.systemGreen.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}
