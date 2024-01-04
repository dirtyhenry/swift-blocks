import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// A transport that checks the status code of the HTTP response and throws an error if it does not match the expected
/// range.
///
/// ## Usage
///
/// Wrapping `URLSession.shared` can be done like so:
///
/// ```swift
/// let transport = StatusCodeCheckingTransport(
///     wrapping: URLSession.shared
/// )
/// ```
///
/// Then, dealing with the error can be achieved like this:
///
/// ```swift
/// do {
///     …
/// } catch let error as WrongStatusCodeError {
///     print(error.localizedDescription)
///     …
/// }
///
/// ```
///
/// - Note: This class conforms to the `Transport` protocol.
@available(iOS 15.0.0, *)
@available(macOS 12.0, *)
public final class StatusCodeCheckingTransport: Transport {
    /// The wrapped transport.
    let wrapped: Transport

    /// A closure defining the expected range of HTTP status codes.
    let expectedStatusCode: (Int) -> Bool

    /// Initializes a `StatusCodeCheckingTransport` instance.
    /// - Parameters:
    ///   - wrapping: The underlying transport to be wrapped.
    ///   - expectedStatusCode: A closure defining the expected range of HTTP status codes.
    ///     Defaults to `expected200to300`.
    public init(wrapping: Transport, expectedStatusCode: @escaping (Int) -> Bool = expected200to300) {
        wrapped = wrapping
        self.expectedStatusCode = expectedStatusCode
    }

    /// Sends a URL request and checks the status code of the HTTP response.
    /// - Parameters:
    ///   - urlRequest: The URL request to be sent.
    ///   - delegate: An optional delegate for handling URL session tasks.
    /// - Returns: A tuple containing the response data and the HTTP URL response.
    /// - Throws: A `WrongStatusCodeError` if the actual status code does not match the expected range.
    public func send(
        urlRequest: URLRequest,
        delegate: URLSessionTaskDelegate?
    ) async throws -> (Data, HTTPURLResponse) {
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

    /// A static method defining the default expected status code range of 200 to 299.
    /// - Parameter code: The HTTP status code to be checked.
    /// - Returns: `true` if the status code is in the range of 200 to 299, `false` otherwise.
    public static func expected200to300(_ code: Int) -> Bool {
        code >= 200 && code < 300
    }
}

/// A type representing an error when the expected HTTP status code is not received.
public struct WrongStatusCodeError: Error {
    /// The actual HTTP status code received.
    public let statusCode: Int

    /// The HTTP URL response associated with the error.
    public let response: HTTPURLResponse?

    /// The response body data associated with the error.
    public let responseBody: Data?

    /// Initializes a `WrongStatusCodeError` instance.
    /// - Parameters:
    ///   - statusCode: The actual HTTP status code received.
    ///   - response: The HTTP URL response associated with the error.
    ///   - responseBody: The response body data associated with the error.
    public init(statusCode: Int, response: HTTPURLResponse?, responseBody: Data?) {
        self.statusCode = statusCode
        self.response = response
        self.responseBody = responseBody
    }
}

extension WrongStatusCodeError: LocalizedError {
    // MARK: - Describing the error

    /// A localized description of the error.
    public var errorDescription: String? {
        "Unexpected HTTP status code: \(statusCode)"
    }
}
