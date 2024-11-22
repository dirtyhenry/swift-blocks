#if canImport(OSLog)
import Foundation
import OSLog

/// A transport wrapper that will log network activity to the unified logging system.
///
/// This wrapper should be used for **debugging purposes only**, since it will output
/// both requests and responses in the console with a `public` privacy by default.
@available(iOS 15.0.0, *)
@available(macOS 12.0, *)
public final class LoggingTransport: Transport {
    let wrapped: Transport
    let logger: Logger

    public init(
        wrapping: Transport,
        subsystem: String,
        category: String = "Networking"
    ) {
        wrapped = wrapping
        logger = Logger(subsystem: subsystem, category: category)
    }

    public func send(
        urlRequest: URLRequest,
        delegate: URLSessionTaskDelegate?
    ) async throws -> (Data, HTTPURLResponse) {
        logger.debug("📤 \(urlRequest, privacy: .public)")
        let (data, httpResponse) = try await wrapped.send(urlRequest: urlRequest, delegate: delegate)
        if let dataAsString = String(data: data, encoding: .utf8) {
            logger.debug("📥 \(dataAsString, privacy: .public) \(httpResponse, privacy: .public)")
        } else {
            logger.debug("📥 \(data, privacy: .public) \(httpResponse, privacy: .public)")
        }
        return (data, httpResponse)
    }
}
#endif
