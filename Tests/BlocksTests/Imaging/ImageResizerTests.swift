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

    func testResizeByScale() throws {
        let source = try ImagingTestHelpers.makeImage(width: 2000, height: 1000)
        let resized = try ImageResizer.resize(source, scale: 0.5)
        XCTAssertEqual(resized.width, 1000)
        XCTAssertEqual(resized.height, 500)
    }
}

#endif
