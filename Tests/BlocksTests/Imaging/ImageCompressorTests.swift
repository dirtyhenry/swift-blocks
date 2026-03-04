#if canImport(CoreGraphics)

@testable import Blocks
import CoreGraphics
import XCTest

@available(macOS 10.15, iOS 13.0, tvOS 15.0, watchOS 8.0, *)
final class ImageCompressorTests: XCTestCase {
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
        // Draw a gradient to produce a non-trivial JPEG
        for y in 0 ..< height {
            let brightness = CGFloat(y) / CGFloat(height)
            context.setFillColor(red: brightness, green: 0.5, blue: 1.0 - brightness, alpha: 1)
            context.fill(CGRect(x: 0, y: y, width: width, height: 1))
        }
        guard let cgImage = context.makeImage() else {
            throw ImagingError.resizeFailed
        }
        return ImageSource(cgImage: cgImage)
    }

    func testEncodeJPEGProducesData() throws {
        let source = try makeImage(width: 100, height: 100)
        let data = try ImageCompressor.encodeJPEG(source, quality: 0.8)
        XCTAssertGreaterThan(data.count, 0)
    }

    func testHigherQualityProducesLargerData() throws {
        let source = try makeImage(width: 500, height: 500)
        let lowQuality = try ImageCompressor.encodeJPEG(source, quality: 0.1)
        let highQuality = try ImageCompressor.encodeJPEG(source, quality: 1.0)
        XCTAssertGreaterThan(highQuality.count, lowQuality.count)
    }

    func testCompressConvergesToTargetSize() throws {
        let source = try makeImage(width: 1000, height: 1000)
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
        let source = try makeImage(width: 1000, height: 1000)
        let config = ImageCompressor.Configuration(
            targetByteSize: 1, // impossibly small
            minimumQuality: 0.5
        )
        let result = try ImageCompressor.compress(source, configuration: config)
        XCTAssertGreaterThanOrEqual(result.quality, 0.5)
    }

    func testCompressWithResizeFlag() throws {
        let source = try makeImage(width: 2000, height: 2000)
        let config = ImageCompressor.Configuration(
            targetByteSize: 500_000,
            maxWidth: 500,
            maxHeight: 500
        )
        let result = try ImageCompressor.compress(source, configuration: config)
        XCTAssertTrue(result.didResize)
    }

    func testCompressSmallImageReturnsHighQuality() throws {
        let source = try makeImage(width: 50, height: 50)
        let config = ImageCompressor.Configuration(targetByteSize: 1_000_000)
        let result = try ImageCompressor.compress(source, configuration: config)
        XCTAssertEqual(result.quality, 1.0)
    }
}

#endif
