#if canImport(CoreGraphics)

import Foundation

/// Errors that can occur during image processing operations.
public enum ImagingError: LocalizedError, Sendable {
    case invalidImageData
    case resizeFailed
    case compressionFailed
    case contextCreationFailed
    case documentDetectionFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidImageData:
            "The provided data could not be decoded as an image."
        case .resizeFailed:
            "Failed to resize the image."
        case .compressionFailed:
            "Failed to compress the image."
        case .contextCreationFailed:
            "Failed to create a graphics context."
        case let .documentDetectionFailed(reason):
            "Document detection failed: \(reason)"
        }
    }
}

#endif
