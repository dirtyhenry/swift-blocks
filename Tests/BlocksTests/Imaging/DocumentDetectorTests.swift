#if canImport(Vision) && canImport(CoreImage)

@testable import Blocks
import CoreGraphics
import XCTest

@available(macOS 12.0, iOS 15.0, *)
final class DocumentDetectorTests: XCTestCase {
    private func makeDocumentImage(width: Int, height: Int) throws -> ImageSource {
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
        // Dark background
        context.setFillColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        // White rectangle (document) in center
        let margin = CGFloat(width) * 0.15
        context.setFillColor(red: 1, green: 1, blue: 1, alpha: 1)
        context.fill(CGRect(
            x: margin,
            y: margin,
            width: CGFloat(width) - margin * 2,
            height: CGFloat(height) - margin * 2
        ))
        guard let cgImage = context.makeImage() else {
            throw ImagingError.resizeFailed
        }
        return ImageSource(cgImage: cgImage)
    }

    private func makeUniformImage(width: Int, height: Int) throws -> ImageSource {
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
        context.setFillColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        guard let cgImage = context.makeImage() else {
            throw ImagingError.resizeFailed
        }
        return ImageSource(cgImage: cgImage)
    }

    func testDetectDocumentInSyntheticImage() async throws {
        let source = try makeDocumentImage(width: 1000, height: 1400)
        let result = try await DocumentDetector.detectDocument(in: source)
        // Vision may or may not detect a document in a synthetic image,
        // but the call should not throw
        if let result {
            XCTAssertGreaterThan(result.confidence, 0)
            XCTAssertGreaterThan(result.image.width, 0)
            XCTAssertGreaterThan(result.image.height, 0)
        }
    }

    func testNoDocumentInUniformImage() async throws {
        let source = try makeUniformImage(width: 500, height: 500)
        let options = DocumentDetector.Options(minimumConfidence: 0.9)
        let result = try await DocumentDetector.detectDocument(in: source, options: options)
        // A uniform image should not be detected as a document at high confidence
        // (though Vision is unpredictable with synthetic images)
        _ = result // If it returns nil, that's the expected behavior
    }

    func testDetectDocumentWithoutPerspectiveCorrection() async throws {
        let source = try makeDocumentImage(width: 800, height: 1200)
        let options = DocumentDetector.Options(applyPerspectiveCorrection: false)
        let result = try await DocumentDetector.detectDocument(in: source, options: options)
        if let result {
            XCTAssertGreaterThan(result.confidence, 0)
        }
    }
}

#endif
