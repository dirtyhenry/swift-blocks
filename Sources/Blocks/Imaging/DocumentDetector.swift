#if canImport(Vision) && canImport(CoreImage)

import CoreGraphics
import CoreImage
import Vision

/// Stateless namespace for Vision-based document detection and perspective correction.
@available(macOS 12.0, iOS 15.0, *)
public enum DocumentDetector {
    /// Options controlling document detection behavior.
    public struct Options: Sendable {
        /// Whether to apply perspective correction to the detected document. Defaults to `true`.
        public var applyPerspectiveCorrection: Bool
        /// Minimum confidence threshold for detection (0.0–1.0). Defaults to 0.5.
        public var minimumConfidence: Float

        public init(
            applyPerspectiveCorrection: Bool = true,
            minimumConfidence: Float = 0.5
        ) {
            self.applyPerspectiveCorrection = applyPerspectiveCorrection
            self.minimumConfidence = minimumConfidence
        }
    }

    /// A quadrilateral defined by four corners in normalized image coordinates (0.0–1.0).
    public struct Quadrilateral: Sendable {
        public let topLeft: CGPoint
        public let topRight: CGPoint
        public let bottomLeft: CGPoint
        public let bottomRight: CGPoint
    }

    /// The result of a document detection operation.
    public struct DetectionResult: Sendable {
        /// The cropped (and optionally perspective-corrected) document image.
        public let image: ImageSource
        /// The detection confidence (0.0–1.0).
        public let confidence: Float
        /// The detected document boundary in normalized coordinates.
        public let quadrilateral: Quadrilateral
    }

    /// Detects a document in the given image.
    ///
    /// Returns `nil` if no document is detected above the confidence threshold.
    public static func detectDocument(
        in source: ImageSource,
        options: Options = Options()
    ) async throws -> DetectionResult? {
        let request = VNDetectDocumentSegmentationRequest()
        let handler = VNImageRequestHandler(cgImage: source.cgImage, options: [:])

        try handler.perform([request])

        guard let observation = request.results?.first,
              observation.confidence >= options.minimumConfidence
        else {
            return nil
        }

        let quad = Quadrilateral(
            topLeft: observation.topLeft,
            topRight: observation.topRight,
            bottomLeft: observation.bottomLeft,
            bottomRight: observation.bottomRight
        )

        let outputImage: ImageSource = if options.applyPerspectiveCorrection {
            try applyPerspectiveCorrection(
                to: source,
                quadrilateral: quad
            )
        } else {
            try cropToQuadrilateral(source: source, quad: quad)
        }

        return DetectionResult(
            image: outputImage,
            confidence: observation.confidence,
            quadrilateral: quad
        )
    }

    private static func applyPerspectiveCorrection(
        to source: ImageSource,
        quadrilateral: Quadrilateral
    ) throws -> ImageSource {
        let ciImage = CIImage(cgImage: source.cgImage)
        let width = CGFloat(source.width)
        let height = CGFloat(source.height)

        guard let filter = CIFilter(name: "CIPerspectiveCorrection") else {
            throw ImagingError.documentDetectionFailed("CIPerspectiveCorrection filter unavailable")
        }

        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(
            CIVector(x: quadrilateral.topLeft.x * width, y: quadrilateral.topLeft.y * height),
            forKey: "inputTopLeft"
        )
        filter.setValue(
            CIVector(x: quadrilateral.topRight.x * width, y: quadrilateral.topRight.y * height),
            forKey: "inputTopRight"
        )
        filter.setValue(
            CIVector(x: quadrilateral.bottomLeft.x * width, y: quadrilateral.bottomLeft.y * height),
            forKey: "inputBottomLeft"
        )
        filter.setValue(
            CIVector(
                x: quadrilateral.bottomRight.x * width,
                y: quadrilateral.bottomRight.y * height
            ),
            forKey: "inputBottomRight"
        )

        guard let outputCIImage = filter.outputImage else {
            throw ImagingError.documentDetectionFailed("Perspective correction produced no output")
        }

        let context = CIContext()
        guard let cgImage = context.createCGImage(outputCIImage, from: outputCIImage.extent) else {
            throw ImagingError.documentDetectionFailed("Failed to render corrected image")
        }

        return ImageSource(cgImage: cgImage)
    }

    private static func cropToQuadrilateral(
        source: ImageSource,
        quad: Quadrilateral
    ) throws -> ImageSource {
        let width = CGFloat(source.width)
        let height = CGFloat(source.height)

        let minX = min(quad.topLeft.x, quad.bottomLeft.x) * width
        let maxX = max(quad.topRight.x, quad.bottomRight.x) * width
        let minY = min(quad.bottomLeft.y, quad.bottomRight.y) * height
        let maxY = max(quad.topLeft.y, quad.topRight.y) * height

        let cropRect = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)

        guard let cropped = source.cgImage.cropping(to: cropRect) else {
            throw ImagingError.documentDetectionFailed("Failed to crop to document bounds")
        }

        return ImageSource(cgImage: cropped)
    }
}

#endif
