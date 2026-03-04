#if canImport(CoreGraphics)

import CoreGraphics

/// Stateless namespace for image resizing operations.
@available(macOS 10.15, iOS 13.0, tvOS 15.0, watchOS 8.0, *)
public enum ImageResizer {
    /// Resizes an image to fit within the given maximum dimensions, preserving aspect ratio.
    ///
    /// Returns the original image unchanged if it already fits within the bounds.
    public static func resize(
        _ source: ImageSource,
        maxWidth: Int,
        maxHeight: Int
    ) throws -> ImageSource {
        guard source.width > maxWidth || source.height > maxHeight else {
            return source
        }

        let widthRatio = CGFloat(maxWidth) / CGFloat(source.width)
        let heightRatio = CGFloat(maxHeight) / CGFloat(source.height)
        let scale = min(widthRatio, heightRatio)

        return try resize(source, scale: scale)
    }

    /// Resizes an image by the given scale factor.
    public static func resize(
        _ source: ImageSource,
        scale: CGFloat
    ) throws -> ImageSource {
        let newWidth = Int(CGFloat(source.width) * scale)
        let newHeight = Int(CGFloat(source.height) * scale)

        guard newWidth > 0, newHeight > 0 else {
            throw ImagingError.resizeFailed
        }

        let colorSpace = source.cgImage.colorSpace ?? CGColorSpaceCreateDeviceRGB()

        // Use premultipliedLast (RGBA) which CGContext always supports.
        // Source images (e.g. JPEG-decoded) may carry alphaInfo=.none which
        // CGContext rejects for RGB color spaces.
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)

        guard let context = CGContext(
            data: nil,
            width: newWidth,
            height: newHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            throw ImagingError.contextCreationFailed
        }

        context.interpolationQuality = .high
        context.draw(source.cgImage, in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))

        guard let resizedImage = context.makeImage() else {
            throw ImagingError.resizeFailed
        }

        return ImageSource(cgImage: resizedImage)
    }
}

#endif
