#if canImport(CoreGraphics)

@testable import Blocks
import CoreGraphics
import Foundation
import ImageIO

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
        for row in 0 ..< height {
            let brightness = CGFloat(row) / CGFloat(height)
            context.setFillColor(red: brightness, green: 0.5, blue: 1.0 - brightness, alpha: 1)
            context.fill(CGRect(x: 0, y: row, width: width, height: 1))
        }
        return try makeImageSource(from: context)
    }

    /// Creates a test image simulating a document on a dark background.
    ///
    /// `documentRect` uses Core Graphics coordinates, with the origin at the bottom left.
    /// If it is `nil`, the document fills the image with a margin of 15% of the width.
    static func makeDocumentImage(width: Int, height: Int, documentRect: CGRect? = nil) throws -> ImageSource {
        let context = try makeContext(width: width, height: height)
        context.setFillColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        let margin = CGFloat(width) * 0.15
        context.setFillColor(red: 1, green: 1, blue: 1, alpha: 1)
        context.fill(documentRect ?? CGRect(
            x: margin,
            y: margin,
            width: CGFloat(width) - margin * 2,
            height: CGFloat(height) - margin * 2
        ))
        return try makeImageSource(from: context)
    }

    /// Creates a test image where each pixel has a different color.
    static func makePixelGridImage(width: Int, height: Int) throws -> ImageSource {
        let context = try makeContext(width: width, height: height)
        for row in 0 ..< height {
            for column in 0 ..< width {
                let index = CGFloat(row * width + column + 1) / CGFloat(width * height)
                context.setFillColor(red: index, green: 1 - index, blue: CGFloat(column % 2), alpha: 1)
                context.fill(CGRect(x: column, y: row, width: 1, height: 1))
            }
        }
        return try makeImageSource(from: context)
    }

    /// Encodes an image as PNG data with the given orientation property.
    static func encodePNG(_ source: ImageSource, orientation: CGImagePropertyOrientation) throws -> Data {
        let data = NSMutableData()
        let type = "public.png" as CFString
        guard let destination = CGImageDestinationCreateWithData(data as CFMutableData, type, 1, nil) else {
            throw ImagingError.compressionFailed
        }
        let properties: [CFString: Any] = [kCGImagePropertyOrientation: orientation.rawValue]
        CGImageDestinationAddImage(destination, source.cgImage, properties as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            throw ImagingError.compressionFailed
        }
        return data as Data
    }

    /// Returns the RGBA bytes of an image, drawn in sRGB.
    static func pixels(of image: CGImage) throws -> [UInt8] {
        let context = try makeContext(width: image.width, height: image.height)
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        guard let data = context.data else {
            throw ImagingError.contextCreationFailed
        }
        let buffer = data.bindMemory(to: UInt8.self, capacity: image.width * image.height * 4)
        return Array(UnsafeBufferPointer(start: buffer, count: image.width * image.height * 4))
    }

    private static func makeContext(width: Int, height: Int) throws -> CGContext {
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                  data: nil,
                  width: width,
                  height: height,
                  bitsPerComponent: 8,
                  bytesPerRow: width * 4,
                  space: colorSpace,
                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              )
        else {
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
