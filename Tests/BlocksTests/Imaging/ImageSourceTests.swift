#if canImport(CoreGraphics) && canImport(ImageIO)

@testable import Blocks
import CoreGraphics
import Foundation
import ImageIO
import XCTest

@available(macOS 10.15, iOS 13.0, tvOS 15.0, watchOS 8.0, *)
final class ImageSourceTests: XCTestCase {
    private let orientations: [CGImagePropertyOrientation] = [
        .up, .upMirrored, .down, .downMirrored, .left, .leftMirrored, .right, .rightMirrored
    ]

    func testInitWithDataAppliesOrientationLikeImageIO() throws {
        let image = try ImagingTestHelpers.makePixelGridImage(width: 3, height: 2)

        for orientation in orientations {
            let data = try ImagingTestHelpers.encodePNG(image, orientation: orientation)
            let source = try ImageSource(data: data)
            let expected = try XCTUnwrap(Self.imageIOOrientedImage(from: data, maxDimension: 3))

            XCTAssertEqual(source.width, expected.width, "\(orientation)")
            XCTAssertEqual(source.height, expected.height, "\(orientation)")
            XCTAssertEqual(
                try ImagingTestHelpers.pixels(of: source.cgImage),
                try ImagingTestHelpers.pixels(of: expected),
                "\(orientation)"
            )
        }
    }

    func testUpOrientationKeepsTheImage() throws {
        let source = try ImagingTestHelpers.makePixelGridImage(width: 3, height: 2)
        XCTAssertTrue(try source.applyingOrientation(.up).cgImage === source.cgImage)
    }

    func testInitWithInvalidDataThrows() {
        XCTAssertThrowsError(try ImageSource(data: Data("not an image".utf8)))
    }

    /// Uses ImageIO to apply the orientation, as a reference.
    private static func imageIOOrientedImage(from data: Data, maxDimension: Int) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }
}

#endif
