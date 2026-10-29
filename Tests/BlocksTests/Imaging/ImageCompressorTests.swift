#if canImport(CoreGraphics)

@testable import Blocks
import CoreGraphics
import XCTest

@available(macOS 10.15, iOS 13.0, tvOS 15.0, watchOS 8.0, *)
final class ImageCompressorTests: XCTestCase {
    func testEncodeJPEGProducesData() throws {
        let source = try ImagingTestHelpers.makeGradientImage(width: 100, height: 100)
        let data = try ImageCompressor.encodeJPEG(source, quality: 0.8)
        XCTAssertGreaterThan(data.count, 0)
    }

    func testHigherQualityProducesLargerData() throws {
        let source = try ImagingTestHelpers.makeGradientImage(width: 500, height: 500)
        let lowQuality = try ImageCompressor.encodeJPEG(source, quality: 0.1)
        let highQuality = try ImageCompressor.encodeJPEG(source, quality: 1.0)
        XCTAssertGreaterThan(highQuality.count, lowQuality.count)
    }

    func testCompressConvergesToTargetSize() throws {
        let source = try ImagingTestHelpers.makeGradientImage(width: 1000, height: 1000)
        let targetSize = 50000
        let config = ImageCompressor.Configuration(
            targetByteSize: targetSize,
            tolerance: 0.15,
            maxIterations: 10
        )
        let result = try ImageCompressor.compress(source, configuration: config)
        // Allow wider margin for convergence
        XCTAssertLessThanOrEqual(result.byteSize, Int(Double(targetSize) * 1.3))
    }

    func testCompressRespectsMinimumQuality() throws {
        let source = try ImagingTestHelpers.makeGradientImage(width: 1000, height: 1000)
        let config = ImageCompressor.Configuration(
            targetByteSize: 1, // impossibly small
            minimumQuality: 0.5
        )
        let result = try ImageCompressor.compress(source, configuration: config)
        XCTAssertGreaterThanOrEqual(result.quality, 0.5)
    }

    func testCompressWithResizeFlag() throws {
        let source = try ImagingTestHelpers.makeGradientImage(width: 2000, height: 2000)
        let config = ImageCompressor.Configuration(
            targetByteSize: 500_000,
            maxWidth: 500,
            maxHeight: 500
        )
        let result = try ImageCompressor.compress(source, configuration: config)
        XCTAssertTrue(result.didResize)
    }

    func testCompressResizesWithOnlyMaxWidth() throws {
        let source = try ImagingTestHelpers.makeGradientImage(width: 2000, height: 1000)
        let config = ImageCompressor.Configuration(targetByteSize: 500_000, maxWidth: 500)
        let result = try ImageCompressor.compress(source, configuration: config)
        XCTAssertTrue(result.didResize)
        let output = try ImageSource(data: result.data)
        XCTAssertEqual(output.width, 500)
        XCTAssertEqual(output.height, 250)
    }

    func testCompressResizesWithOnlyMaxHeight() throws {
        let source = try ImagingTestHelpers.makeGradientImage(width: 2000, height: 1000)
        let config = ImageCompressor.Configuration(targetByteSize: 500_000, maxHeight: 100)
        let result = try ImageCompressor.compress(source, configuration: config)
        let output = try ImageSource(data: result.data)
        XCTAssertEqual(output.width, 200)
        XCTAssertEqual(output.height, 100)
    }

    func testCompressDoesNotExceedReachableTarget() throws {
        let source = try ImagingTestHelpers.makeGradientImage(width: 1000, height: 1000)
        let low = try ImageCompressor.encodeJPEG(source, quality: 0.1).count
        let high = try ImageCompressor.encodeJPEG(source, quality: 1.0).count
        let targetSize = (low + high) / 2
        let config = ImageCompressor.Configuration(targetByteSize: targetSize, tolerance: 0)
        let result = try ImageCompressor.compress(source, configuration: config)
        XCTAssertLessThanOrEqual(result.byteSize, targetSize)
        XCTAssertEqual(result.byteSize, result.data.count)
    }

    func testCompressSmallImageReturnsHighQuality() throws {
        let source = try ImagingTestHelpers.makeGradientImage(width: 50, height: 50)
        let config = ImageCompressor.Configuration(targetByteSize: 1_000_000)
        let result = try ImageCompressor.compress(source, configuration: config)
        XCTAssertEqual(result.quality, 1.0)
    }
}

#endif
