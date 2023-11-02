import Foundation

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
    import os

    @available(iOS 15.0.0, *)
    @available(macOS 12.0, *)
    public final class LoggingTransport: Transport {
        let wrapped: Transport
        let logger: Logger

        public init(wrapping: Transport, subsystem: String, category: String = "Networking") {
            wrapped = wrapping
            logger = Logger(subsystem: subsystem, category: category)
        }

        public func send(urlRequest: URLRequest, delegate: URLSessionTaskDelegate?) async throws -> (Data, HTTPURLResponse) {
            logger.debug("Sending request: \(urlRequest)")
            let (data, httpResponse) = try await wrapped.send(urlRequest: urlRequest, delegate: delegate)
            if let dataAsString = String(data: data, encoding: .utf8) {
                logger.debug("Got response: \(dataAsString) \(httpResponse)")
            } else {
                logger.debug("Got response: \(data) \(httpResponse)")
            }
            return (data, httpResponse)
        }
    }
#endif
