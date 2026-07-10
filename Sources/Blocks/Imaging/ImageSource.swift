#if canImport(CoreGraphics)

import CoreGraphics
import Foundation
import ImageIO

/// A cross-platform wrapper around `CGImage` providing a canonical image type
/// for processing operations.
@available(macOS 10.15, iOS 13.0, tvOS 15.0, watchOS 8.0, *)
public struct ImageSource: Sendable {
    /// The underlying Core Graphics image.
    public let cgImage: CGImage

    /// Creates an image source from an existing `CGImage`.
    public init(cgImage: CGImage) {
        self.cgImage = cgImage
    }

    /// Creates an image source by decoding image data (JPEG, PNG, etc.).
    public init(data: Data) throws {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else {
            throw ImagingError.invalidImageData
        }
        self.cgImage = cgImage
    }

    /// The width of the image in pixels.
    public var width: Int {
        cgImage.width
    }

    /// The height of the image in pixels.
    public var height: Int {
        cgImage.height
    }
}

#if canImport(UIKit)
import UIKit

@available(macOS 10.15, iOS 13.0, tvOS 15.0, watchOS 8.0, *)
public extension ImageSource {
    /// Creates an image source from a `UIImage`.
    init(uiImage: UIImage) throws {
        guard let cgImage = uiImage.cgImage else {
            throw ImagingError.invalidImageData
        }
        self.cgImage = cgImage
    }

    /// Converts this image source to a `UIImage`.
    var uiImage: UIImage {
        UIImage(cgImage: cgImage)
    }
}
#endif

#if canImport(AppKit)
import AppKit

@available(macOS 10.15, iOS 13.0, tvOS 15.0, watchOS 8.0, *)
public extension ImageSource {
    /// Creates an image source from an `NSImage`.
    init(nsImage: NSImage) throws {
        guard let cgImage = nsImage.cgImage(
            forProposedRect: nil,
            context: nil,
            hints: nil
        ) else {
            throw ImagingError.invalidImageData
        }
        self.cgImage = cgImage
    }

    /// Converts this image source to an `NSImage`.
    var nsImage: NSImage {
        NSImage(cgImage: cgImage, size: NSSize(width: width, height: height))
    }
}
#endif

#endif
