#if canImport(CoreGraphics)

import CoreGraphics

/// Operations that change the size of an image.
@available(macOS 10.15, iOS 13.0, tvOS 15.0, watchOS 8.0, *)
public enum ImageResizer {
    /// Makes an image smaller to fit in the given maximum dimensions. The aspect ratio does not change.
    ///
    /// If the image already fits in the dimensions, the function returns the image without a change.
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

    /// Changes the size of an image by the given scale factor.
    public static func resize(
        _ source: ImageSource,
        scale: CGFloat
    ) throws -> ImageSource {
        let newWidth = Int(CGFloat(source.width) * scale)
        let newHeight = Int(CGFloat(source.height) * scale)

        guard newWidth > 0, newHeight > 0 else {
            throw ImagingError.resizeFailed
        }

        let context = try ImageSource.makeBitmapContext(
            width: newWidth,
            height: newHeight,
            preferredColorSpace: source.cgImage.colorSpace
        )
        context.draw(source.cgImage, in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))

        guard let resizedImage = context.makeImage() else {
            throw ImagingError.resizeFailed
        }

        return ImageSource(cgImage: resizedImage)
    }
}

#endif
