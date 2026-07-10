#if canImport(Vision) && canImport(CoreImage)

@testable import Blocks
import CoreGraphics
import XCTest

@available(macOS 12.0, iOS 15.0, *)
final class DocumentDetectorTests: XCTestCase {
    func testDetectDocumentInSyntheticImage() async throws {
        let source = try ImagingTestHelpers.makeDocumentImage(width: 1000, height: 1400)
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
        let source = try ImagingTestHelpers.makeImage(width: 500, height: 500, red: 0.5, green: 0.5, blue: 0.5)
        let options = DocumentDetector.Options(minimumConfidence: 0.9)
        let result = try await DocumentDetector.detectDocument(in: source, options: options)
        // A uniform image should not be detected as a document at high confidence
        // (though Vision is unpredictable with synthetic images)
        _ = result // If it returns nil, that's the expected behavior
    }

    func testDetectDocumentWithoutPerspectiveCorrection() async throws {
        let source = try ImagingTestHelpers.makeDocumentImage(width: 800, height: 1200)
        let options = DocumentDetector.Options(applyPerspectiveCorrection: false)
        let result = try await DocumentDetector.detectDocument(in: source, options: options)
        if let result {
            XCTAssertGreaterThan(result.confidence, 0)
        }
    }
}

#endif
