#if canImport(CoreGraphics)

import CoreGraphics
import Foundation
import ImageIO

/// Stateless namespace for JPEG image compression with target byte size.
@available(macOS 10.15, iOS 13.0, tvOS 15.0, watchOS 8.0, *)
public enum ImageCompressor {
    /// Configuration for image compression.
    public struct Configuration: Sendable {
        /// Target byte size for the compressed output.
        public var targetByteSize: Int
        /// Acceptable tolerance around the target size (0.0–1.0). Defaults to 0.05 (5%).
        public var tolerance: Double
        /// Maximum binary search iterations. Defaults to 8.
        public var maxIterations: Int
        /// Minimum JPEG quality floor (0.0–1.0). Defaults to 0.1.
        public var minimumQuality: CGFloat
        /// Optional maximum width for pre-resize.
        public var maxWidth: Int?
        /// Optional maximum height for pre-resize.
        public var maxHeight: Int?

        public init(
            targetByteSize: Int,
            tolerance: Double = 0.05,
            maxIterations: Int = 8,
            minimumQuality: CGFloat = 0.1,
            maxWidth: Int? = nil,
            maxHeight: Int? = nil
        ) {
            self.targetByteSize = targetByteSize
            self.tolerance = tolerance
            self.maxIterations = maxIterations
            self.minimumQuality = minimumQuality
            self.maxWidth = maxWidth
            self.maxHeight = maxHeight
        }
    }

    /// The result of a compression operation.
    public struct Result: Sendable {
        /// The compressed JPEG data.
        public let data: Data
        /// The JPEG quality used for the final compression.
        public let quality: CGFloat
        /// The size of the compressed data in bytes.
        public let byteSize: Int
        /// Whether the image was resized before compression.
        public let didResize: Bool
    }

    /// Compresses an image to fit within the target byte size using binary search on JPEG quality.
    public static func compress(
        _ source: ImageSource,
        configuration: Configuration
    ) throws -> Result {
        var current = source
        var didResize = false

        if let maxWidth = configuration.maxWidth, let maxHeight = configuration.maxHeight {
            let resized = try ImageResizer.resize(current, maxWidth: maxWidth, maxHeight: maxHeight)
            didResize = resized.cgImage !== current.cgImage
            current = resized
        }

        var low = configuration.minimumQuality
        var high: CGFloat = 1.0
        var bestData = try encodeJPEG(current, quality: high)
        var bestQuality = high

        if bestData.count <= configuration.targetByteSize {
            return Result(data: bestData, quality: bestQuality, byteSize: bestData.count, didResize: didResize)
        }

        let targetSize = configuration.targetByteSize
        let toleranceBytes = Int(Double(targetSize) * configuration.tolerance)
        let lowerBound = targetSize - toleranceBytes
        let upperBound = targetSize + toleranceBytes

        for _ in 0 ..< configuration.maxIterations {
            let mid = (low + high) / 2.0
            let encoded = try encodeJPEG(current, quality: mid)

            if encoded.count >= lowerBound, encoded.count <= upperBound {
                return Result(data: encoded, quality: mid, byteSize: encoded.count, didResize: didResize)
            }

            if encoded.count > targetSize {
                high = mid
            } else {
                low = mid
                bestData = encoded
                bestQuality = mid
            }
        }

        let finalData = try encodeJPEG(current, quality: low)
        return Result(data: finalData, quality: low, byteSize: finalData.count, didResize: didResize)
    }

    /// Encodes an image as JPEG data at the given quality (0.0–1.0).
    public static func encodeJPEG(_ source: ImageSource, quality: CGFloat) throws -> Data {
        let data = NSMutableData()

        guard let destination = CGImageDestinationCreateWithData(
            data as CFMutableData,
            "public.jpeg" as CFString,
            1,
            nil
        ) else {
            throw ImagingError.compressionFailed
        }

        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality
        ]

        CGImageDestinationAddImage(destination, source.cgImage, options as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            throw ImagingError.compressionFailed
        }

        return data as Data
    }
}

#endif
