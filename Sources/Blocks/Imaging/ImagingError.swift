#if canImport(CoreGraphics)

import Foundation

/// The errors of the imaging operations.
public enum ImagingError: LocalizedError, Sendable {
    case invalidImageData
    case resizeFailed
    case compressionFailed
    case contextCreationFailed
    case documentDetectionFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidImageData:
            "The data is not a valid image."
        case .resizeFailed:
            "The image resize failed."
        case .compressionFailed:
            "The image compression failed."
        case .contextCreationFailed:
            "The graphics context creation failed."
        case let .documentDetectionFailed(reason):
            "Document detection failed: \(reason)"
        }
    }
}

#endif
