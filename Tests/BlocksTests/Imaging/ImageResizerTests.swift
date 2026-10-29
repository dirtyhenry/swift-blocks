#if canImport(CoreGraphics)

@testable import Blocks
import CoreGraphics
import XCTest

@available(macOS 10.15, iOS 13.0, tvOS 15.0, watchOS 8.0, *)
final class ImageResizerTests: XCTestCase {
    func testResizePreservesAspectRatioLandscape() throws {
        let source = try ImagingTestHelpers.makeImage(width: 4000, height: 2000)
        let resized = try ImageResizer.resize(source, maxWidth: 2000, maxHeight: 2000)
        XCTAssertEqual(resized.width, 2000)
        XCTAssertEqual(resized.height, 1000)
    }

    func testResizePreservesAspectRatioPortrait() throws {
        let source = try ImagingTestHelpers.makeImage(width: 2000, height: 4000)
        let resized = try ImageResizer.resize(source, maxWidth: 2000, maxHeight: 2000)
        XCTAssertEqual(resized.width, 1000)
        XCTAssertEqual(resized.height, 2000)
    }

    func testResizeNoOpForSmallerImage() throws {
        let source = try ImagingTestHelpers.makeImage(width: 500, height: 300)
        let resized = try ImageResizer.resize(source, maxWidth: 1000, maxHeight: 1000)
        XCTAssertTrue(resized.cgImage === source.cgImage)
    }

    func testResizeSquare() throws {
        let source = try ImagingTestHelpers.makeImage(width: 3000, height: 3000)
        let resized = try ImageResizer.resize(source, maxWidth: 1000, maxHeight: 1000)
        XCTAssertEqual(resized.width, 1000)
        XCTAssertEqual(resized.height, 1000)
    }

    func testResizeGrayscaleImage() throws {
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let context = try XCTUnwrap(CGContext(
            data: nil,
            width: 400,
            height: 200,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ))
        context.setFillColor(gray: 0.5, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: 400, height: 200))
        let source = try ImageSource(cgImage: XCTUnwrap(context.makeImage()))

        let resized = try ImageResizer.resize(source, maxWidth: 100, maxHeight: 100)
        XCTAssertEqual(resized.width, 100)
        XCTAssertEqual(resized.height, 50)
    }

    func testResizeKeepsRGBColorSpace() throws {
        let displayP3 = try XCTUnwrap(CGColorSpace(name: CGColorSpace.displayP3))
        let context = try XCTUnwrap(CGContext(
            data: nil,
            width: 400,
            height: 200,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: displayP3,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        let source = try ImageSource(cgImage: XCTUnwrap(context.makeImage()))

        let resized = try ImageResizer.resize(source, scale: 0.5)
        XCTAssertEqual(resized.cgImage.colorSpace?.name, CGColorSpace.displayP3)
    }

    func testResizeByScale() throws {
        let source = try ImagingTestHelpers.makeImage(width: 2000, height: 1000)
        let resized = try ImageResizer.resize(source, scale: 0.5)
        XCTAssertEqual(resized.width, 1000)
        XCTAssertEqual(resized.height, 500)
    }
}

#endif
