#if canImport(CoreGraphics)

import CoreGraphics
import Foundation
import ImageIO

/// Operations that compress an image to JPEG data of a target size.
@available(macOS 10.15, iOS 13.0, tvOS 15.0, watchOS 8.0, *)
public enum ImageCompressor {
    /// The configuration of a compression.
    public struct Configuration: Sendable {
        /// The target size of the compressed data, in bytes.
        public var targetByteSize: Int
        /// The permitted difference from the target size, as a fraction (0.0–1.0). The default is 0.05 (5%).
        public var tolerance: Double
        /// The maximum number of steps of the quality search. The default is 8.
        public var maxIterations: Int
        /// The lowest JPEG quality that the compression can use (0.0–1.0). The default is 0.1.
        public var minimumQuality: CGFloat
        /// The maximum width of the output, in pixels. If the value is `nil`, the width has no limit.
        public var maxWidth: Int?
        /// The maximum height of the output, in pixels. If the value is `nil`, the height has no limit.
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

    /// The result of a compression.
    public struct Result: Sendable {
        /// The compressed JPEG data.
        public let data: Data
        /// The JPEG quality of the compressed data.
        public let quality: CGFloat
        /// The size of the compressed data, in bytes.
        public let byteSize: Int
        /// A Boolean value that is `true` if the compression made the image smaller before the encoding.
        public let didResize: Bool
    }

    /// Compresses an image to JPEG data that is not larger than the target size.
    ///
    /// The function first makes the image smaller to fit in `maxWidth` and `maxHeight`. Then it
    /// does a binary search on the JPEG quality.
    ///
    /// If the data at `minimumQuality` is larger than the target, the function returns this data.
    /// Compare `byteSize` with the target to find this case.
    public static func compress(
        _ source: ImageSource,
        configuration: Configuration
    ) throws -> Result {
        var current = source
        var didResize = false

        if configuration.maxWidth != nil || configuration.maxHeight != nil {
            let resized = try ImageResizer.resize(
                current,
                maxWidth: configuration.maxWidth ?? .max,
                maxHeight: configuration.maxHeight ?? .max
            )
            didResize = resized.cgImage !== current.cgImage
            current = resized
        }

        let fullQualityData = try encodeJPEG(current, quality: 1.0)
        if fullQualityData.count <= configuration.targetByteSize {
            return Result(data: fullQualityData, quality: 1.0, byteSize: fullQualityData.count, didResize: didResize)
        }

        let targetSize = configuration.targetByteSize
        let toleranceBytes = Int(Double(targetSize) * configuration.tolerance)
        let lowerBound = targetSize - toleranceBytes

        var low = configuration.minimumQuality
        var high: CGFloat = 1.0
        var best: (data: Data, quality: CGFloat)?

        for _ in 0 ..< configuration.maxIterations {
            let mid = (low + high) / 2.0
            let encoded = try encodeJPEG(current, quality: mid)

            if encoded.count > targetSize {
                high = mid
            } else {
                best = (encoded, mid)
                if encoded.count >= lowerBound {
                    break
                }
                low = mid
            }
        }

        let minimumQuality = configuration.minimumQuality
        let (data, quality) = try best ?? (encodeJPEG(current, quality: minimumQuality), minimumQuality)
        return Result(data: data, quality: quality, byteSize: data.count, didResize: didResize)
    }

    /// Encodes an image as JPEG data with the given quality (0.0–1.0).
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
