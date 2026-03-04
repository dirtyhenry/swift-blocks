#if canImport(CoreGraphics)

@testable import Blocks
import CoreGraphics

/// Shared helpers for creating test images in imaging tests.
@available(macOS 10.15, iOS 13.0, tvOS 15.0, watchOS 8.0, *)
enum ImagingTestHelpers {
    /// Creates a test image filled with a solid color.
    static func makeImage(
        width: Int,
        height: Int,
        red: CGFloat = 1,
        green: CGFloat = 0,
        blue: CGFloat = 0
    ) throws -> ImageSource {
        let context = try makeContext(width: width, height: height)
        context.setFillColor(red: red, green: green, blue: blue, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        return try makeImageSource(from: context)
    }

    /// Creates a test image with a vertical gradient (useful for non-trivial JPEG encoding).
    static func makeGradientImage(width: Int, height: Int) throws -> ImageSource {
        let context = try makeContext(width: width, height: height)
        for y in 0 ..< height {
            let brightness = CGFloat(y) / CGFloat(height)
            context.setFillColor(red: brightness, green: 0.5, blue: 1.0 - brightness, alpha: 1)
            context.fill(CGRect(x: 0, y: y, width: width, height: 1))
        }
        return try makeImageSource(from: context)
    }

    /// Creates a test image simulating a document on a dark background.
    static func makeDocumentImage(width: Int, height: Int) throws -> ImageSource {
        let context = try makeContext(width: width, height: height)
        context.setFillColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        let margin = CGFloat(width) * 0.15
        context.setFillColor(red: 1, green: 1, blue: 1, alpha: 1)
        context.fill(CGRect(
            x: margin,
            y: margin,
            width: CGFloat(width) - margin * 2,
            height: CGFloat(height) - margin * 2
        ))
        return try makeImageSource(from: context)
    }

    private static func makeContext(width: Int, height: Int) throws -> CGContext {
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
        return context
    }

    private static func makeImageSource(from context: CGContext) throws -> ImageSource {
        guard let cgImage = context.makeImage() else {
            throw ImagingError.resizeFailed
        }
        return ImageSource(cgImage: cgImage)
    }
}

#endif
