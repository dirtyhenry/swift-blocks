#if canImport(CoreGraphics)

import CoreGraphics
import Foundation
import ImageIO

/// A wrapper around `CGImage` that the imaging operations use as input and output.
///
/// The pixels of an image source are always in the `.up` orientation.
/// The initializers apply the orientation of the input before they keep the pixels.
@available(macOS 10.15, iOS 13.0, tvOS 15.0, watchOS 8.0, *)
public struct ImageSource: Sendable {
    /// The underlying Core Graphics image.
    public let cgImage: CGImage

    /// Creates an image source from a `CGImage`.
    ///
    /// The image source uses the pixels as they are. It does not change their orientation.
    public init(cgImage: CGImage) {
        self.cgImage = cgImage
    }

    /// Creates an image source from encoded image data, for example JPEG or PNG data.
    ///
    /// If the data has an orientation property, the initializer turns the pixels to the `.up`
    /// orientation.
    public init(data: Data) throws {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else {
            throw ImagingError.invalidImageData
        }

        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        let orientation = (properties?[kCGImagePropertyOrientation] as? UInt32)
            .flatMap(CGImagePropertyOrientation.init(rawValue:)) ?? .up

        self = try ImageSource(cgImage: cgImage).applyingOrientation(orientation)
    }

    /// The width of the image in pixels.
    public var width: Int {
        cgImage.width
    }

    /// The height of the image in pixels.
    public var height: Int {
        cgImage.height
    }

    /// Returns an image source with the pixels turned and flipped to the `.up` orientation.
    ///
    /// - Parameter orientation: The orientation of the current pixels.
    public func applyingOrientation(_ orientation: CGImagePropertyOrientation) throws -> ImageSource {
        let sourceWidth = CGFloat(width)
        let sourceHeight = CGFloat(height)

        let swapsAxes: Bool
        switch orientation {
        case .up:
            return self
        case .left, .leftMirrored, .right, .rightMirrored:
            swapsAxes = true
        default:
            swapsAxes = false
        }

        let outputWidth = swapsAxes ? sourceHeight : sourceWidth
        let outputHeight = swapsAxes ? sourceWidth : sourceHeight

        var transform = CGAffineTransform.identity
        switch orientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: outputWidth, y: outputHeight).rotated(by: .pi)
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: outputWidth, y: 0).rotated(by: .pi / 2)
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: outputHeight).rotated(by: -.pi / 2)
        default:
            break
        }

        switch orientation {
        case .upMirrored, .downMirrored, .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: sourceWidth, y: 0).scaledBy(x: -1, y: 1)
        default:
            break
        }

        let context = try Self.makeBitmapContext(
            width: Int(outputWidth),
            height: Int(outputHeight),
            preferredColorSpace: cgImage.colorSpace
        )
        context.concatenate(transform)
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: sourceWidth, height: sourceHeight))

        guard let orientedImage = context.makeImage() else {
            throw ImagingError.contextCreationFailed
        }

        return ImageSource(cgImage: orientedImage)
    }

    /// Makes an 8-bit RGBA bitmap context.
    ///
    /// The context uses `preferredColorSpace` if it is an RGB color space that supports this pixel
    /// format. Thus wide-gamut images keep their colors. Other inputs, for example grayscale scans,
    /// use sRGB.
    static func makeBitmapContext(
        width: Int,
        height: Int,
        preferredColorSpace: CGColorSpace?
    ) throws -> CGContext {
        var colorSpaces: [CGColorSpace] = []
        if let preferredColorSpace, preferredColorSpace.model == .rgb {
            colorSpaces.append(preferredColorSpace)
        }
        colorSpaces.append(CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB())

        for colorSpace in colorSpaces {
            if let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) {
                context.interpolationQuality = .high
                return context
            }
        }

        throw ImagingError.contextCreationFailed
    }
}

#if canImport(UIKit)
import UIKit

@available(macOS 10.15, iOS 13.0, tvOS 15.0, watchOS 8.0, *)
public extension ImageSource {
    /// Creates an image source from a `UIImage`.
    ///
    /// The initializer applies the `imageOrientation` of the image to the pixels. Thus a photo from
    /// the camera keeps the orientation that the user sees.
    init(uiImage: UIImage) throws {
        guard let cgImage = uiImage.cgImage else {
            throw ImagingError.invalidImageData
        }
        self = try ImageSource(cgImage: cgImage)
            .applyingOrientation(CGImagePropertyOrientation(uiImage.imageOrientation))
    }

    /// Converts this image source to a `UIImage`.
    var uiImage: UIImage {
        UIImage(cgImage: cgImage)
    }
}

private extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
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
