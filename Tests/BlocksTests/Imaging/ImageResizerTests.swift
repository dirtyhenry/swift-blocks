#if canImport(CoreGraphics)

@testable import Blocks
import CoreGraphics
import XCTest

@available(macOS 10.15, iOS 13.0, tvOS 15.0, watchOS 8.0, *)
final class ImageResizerTests: XCTestCase {
    private func makeImage(width: Int, height: Int) throws -> ImageSource {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw ImagingError.contextCreationFailed
        }
        context.setFillColor(red: 1, green: 0, blue: 0, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        guard let cgImage = context.makeImage() else {
            throw ImagingError.resizeFailed
        }
        return ImageSource(cgImage: cgImage)
    }

    func testResizePreservesAspectRatioLandscape() throws {
        let source = try makeImage(width: 4000, height: 2000)
        let resized = try ImageResizer.resize(source, maxWidth: 2000, maxHeight: 2000)
        XCTAssertEqual(resized.width, 2000)
        XCTAssertEqual(resized.height, 1000)
    }

    func testResizePreservesAspectRatioPortrait() throws {
        let source = try makeImage(width: 2000, height: 4000)
        let resized = try ImageResizer.resize(source, maxWidth: 2000, maxHeight: 2000)
        XCTAssertEqual(resized.width, 1000)
        XCTAssertEqual(resized.height, 2000)
    }

    func testResizeNoOpForSmallerImage() throws {
        let source = try makeImage(width: 500, height: 300)
        let resized = try ImageResizer.resize(source, maxWidth: 1000, maxHeight: 1000)
        XCTAssertTrue(resized.cgImage === source.cgImage)
    }

    func testResizeSquare() throws {
        let source = try makeImage(width: 3000, height: 3000)
        let resized = try ImageResizer.resize(source, maxWidth: 1000, maxHeight: 1000)
        XCTAssertEqual(resized.width, 1000)
        XCTAssertEqual(resized.height, 1000)
    }

    func testResizeByScale() throws {
        let source = try makeImage(width: 2000, height: 1000)
        let resized = try ImageResizer.resize(source, scale: 0.5)
        XCTAssertEqual(resized.width, 1000)
        XCTAssertEqual(resized.height, 500)
    }
}

#endif
