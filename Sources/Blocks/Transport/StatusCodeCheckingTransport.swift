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
                throw WrongStatusCodeError(
                    statusCode: httpResponse.statusCode,
                    response: httpResponse,
                    responseBody: data
                )
            }

            return (data, httpResponse)
        }

        public static func expected200to300(_ code: Int) -> Bool {
            code >= 200 && code < 300
        }
    }

    /// Signals that a response's status code was wrong.
    public struct WrongStatusCodeError: Error {
        public let statusCode: Int
        public let response: HTTPURLResponse?
        public let responseBody: Data?
        public init(statusCode: Int, response: HTTPURLResponse?, responseBody: Data?) {
            self.statusCode = statusCode
            self.response = response
            self.responseBody = responseBody
        }
    }
#endif
