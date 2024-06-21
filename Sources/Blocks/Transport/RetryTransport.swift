import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// A transport class that retries sending requests based on specified conditions and delays.
///
/// This class wraps around another `Transport` instance and provides retry functionality based on custom conditions
/// and delays.
///
/// - Note: This class is available on iOS 15.0.0 and macOS 12.0 or later.
@available(iOS 15.0.0, *)
@available(macOS 12.0, *)
public final class RetryTransport: Transport {
    let wrapped: Transport

    let canRetry: (Error, Int) -> Bool
    let delay: (Int) async -> Void

    /// Initializes a new `RetryTransport` instance.
    ///
    /// - Parameters:
    ///   - wrapping: The underlying `Transport` instance to wrap.
    ///   - canRetry: A closure that determines whether a retry attempt should be made based on the error and attempt
    ///     count.
    ///   - delay: A closure that specifies the delay before the next retry attempt.
    public init(
        wrapping: Transport,
        canRetry: @escaping (Error, Int) -> Bool = max(of: 3),
        delay: @escaping (Int) async -> Void = noDelay
    ) {
        wrapped = wrapping
        self.canRetry = canRetry
        self.delay = delay
    }

    /// Sends a URL request and returns the response.
    ///
    /// - Parameters:
    ///   - urlRequest: The URL request to send.
    ///   - delegate: An optional URLSessionTaskDelegate for handling the request.
    /// - Returns: A tuple containing the response data and the HTTPURLResponse.
    /// - Throws: An error if the request fails after retry attempts.
    public func send(
        urlRequest: URLRequest,
        delegate: URLSessionTaskDelegate?
    ) async throws -> (Data, HTTPURLResponse) {
        var nbAttempts = 0
        var errors: [Error] = []

        while nbAttempts == 0 || (!errors.isEmpty && canRetry(errors.last!, nbAttempts)) {
            do {
                let (data, httpResponse) = try await wrapped.send(urlRequest: urlRequest, delegate: delegate)
                return (data, httpResponse)
            } catch {
                nbAttempts += 1
                errors.append(error)
                await delay(nbAttempts)
            }
        }

        throw RetryTransportError(transportErrors: errors)
    }

    // - MARK: Retry strategies

    public static func max(of maxNumberOfAttempts: Int) -> ((Error, Int) -> Bool) {
        { _, nbAttempt in
            nbAttempt < maxNumberOfAttempts
        }
    }

    // - MARK: Delay strategies

    /// A delay strategy that applies no delay between retry attempts.
    ///
    /// - Parameter nbAttempt: The number of retry attempts made so far.
    public static func noDelay(nbAttempt _: Int) {}
}

/// An error type representing multiple errors encountered during retry attempts by `RetryTransport`.
public struct RetryTransportError: Error {
    public let transportErrors: [Error]

    /// Initializes a new `RetryTransportError` instance with the provided transport errors.
    ///
    /// - Parameter transportErrors: An array of errors encountered during retry attempts.
    public init(transportErrors: [Error]) {
        self.transportErrors = transportErrors
    }
}

extension RetryTransportError: LocalizedError {
    public var errorDescription: String? {
        "Sending the request threw more errors than RetryTransport could retry: \(transportErrors.count)"
    }
}
