import Foundation

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
    @available(iOS 15.0.0, *)
    @available(macOS 12.0, *)
    public final class StatusCodeCheckingTransport: Transport {
        let wrapped: Transport
        let expectedStatusCode: (Int) -> Bool

        public init(wrapping: Transport, expectedStatusCode: @escaping (Int) -> Bool = expected200to300) {
            wrapped = wrapping
            self.expectedStatusCode = expectedStatusCode
        }

        public func send(urlRequest: URLRequest, delegate: URLSessionTaskDelegate?) async throws -> (Data, HTTPURLResponse) {
            let (data, httpResponse) = try await wrapped.send(urlRequest: urlRequest, delegate: delegate)

            guard expectedStatusCode(httpResponse.statusCode) else {
                throw TransportError.unexpectedHTTPStatusCode(httpResponse.statusCode)
            }

            return (data, httpResponse)
        }

        public static func expected200to300(_ code: Int) -> Bool {
            code >= 200 && code < 300
        }
    }
#endif
