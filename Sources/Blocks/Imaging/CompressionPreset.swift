#if canImport(CoreGraphics)

import CoreGraphics

/// Predefined compression configurations for common use cases.
@available(macOS 10.15, iOS 13.0, tvOS 15.0, watchOS 8.0, *)
public enum CompressionPreset: Sendable {
    /// High quality: 2MB target, 4096px max dimension.
    case highQuality
    /// Balanced: 800KB target, 2048px max dimension.
    case balanced
    /// Compact: 300KB target, 1024px max dimension.
    case compact
    /// Custom configuration.
    case custom(ImageCompressor.Configuration)

    /// The compression configuration for this preset.
    public var configuration: ImageCompressor.Configuration {
        switch self {
        case .highQuality:
            ImageCompressor.Configuration(
                targetByteSize: 2_000_000,
                maxWidth: 4096,
                maxHeight: 4096
            )
        case .balanced:
            ImageCompressor.Configuration(
                targetByteSize: 800_000,
                maxWidth: 2048,
                maxHeight: 2048
            )
        case .compact:
            ImageCompressor.Configuration(
                targetByteSize: 300_000,
                maxWidth: 1024,
                maxHeight: 1024
            )
        case let .custom(configuration):
            configuration
        }
    }
}

#if canImport(Network)

import Network

@available(macOS 10.15, iOS 13.0, tvOS 15.0, watchOS 8.0, *)
public extension CompressionPreset {
    /// Returns a suitable compression preset for the given network condition.
    static func preset(for condition: NetworkCondition) -> CompressionPreset {
        switch condition {
        case .excellent:
            .highQuality
        case .good:
            .balanced
        case .poor, .offline:
            .compact
        }
    }
}

#endif

#endif
