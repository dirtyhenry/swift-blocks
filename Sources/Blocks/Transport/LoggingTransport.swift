#if canImport(OSLog)
import Foundation
import OSLog

/// A transport wrapper that logs network activity to the unified logging system.
///
/// Use this wrapper **for debug purposes only**. It writes requests and responses to the console with a `public`
/// privacy.
///
/// Each request gets a number, for example `#12`. The request and its response show the same number. Use this number
/// to find the response of a request in Console.app.
///
/// The first line of each message is a summary:
///
/// ```
/// → #12 POST https://example.com/graphql (SignIn)
/// ← #12 200 POST https://example.com/graphql · 181 ms · 1.2 KB
/// ```
///
/// The other lines contain the body and then the headers. Select a message in Console.app to see them.
///
/// The log level shows the result of the request:
///
/// - Requests and status codes below 400 use the `debug` level.
/// - Status codes from 400 to 499 use the `error` level.
/// - Status codes from 500 and thrown errors use the `fault` level.
///
/// The unified logging system cuts messages at approximately 1 KB. Thus, this wrapper cuts long messages. It writes
/// the body before the headers, thus the cut removes the headers first.
@available(iOS 15.0.0, *)
@available(macOS 12.0, *)
public final class LoggingTransport: Transport {
    /// The options of a `LoggingTransport`.
    public struct Configuration: Sendable {
        /// The names of the header fields to hide in the logs.
        ///
        /// The comparison of names is not case-sensitive.
        public var redactedHeaderFields: Set<String>

        /// Makes a configuration.
        ///
        /// - Parameter redactedHeaderFields: The names of the header fields to hide in the logs.
        ///   By default, the logs hide `Authorization`, `Cookie` and `Set-Cookie`.
        public init(redactedHeaderFields: Set<String> = ["Authorization", "Cookie", "Set-Cookie"]) {
            self.redactedHeaderFields = redactedHeaderFields
        }
    }

    let wrapped: Transport
    let logger: Logger
    let formatter: HTTPLogFormatter
    private let counter = RequestCounter()

    public init(
        wrapping: Transport,
        subsystem: String,
        category: String = "Networking",
        configuration: Configuration = .init()
    ) {
        wrapped = wrapping
        logger = Logger(subsystem: subsystem, category: category)
        formatter = HTTPLogFormatter(redactedHeaderFields: configuration.redactedHeaderFields)
    }

    public func send(
        urlRequest: URLRequest,
        delegate: URLSessionTaskDelegate?
    ) async throws -> (Data, HTTPURLResponse) {
        let id = counter.next()
        log(formatter.requestMessage(id: id, request: urlRequest), level: .debug)

        let start = ProcessInfo.processInfo.systemUptime
        do {
            let (data, httpResponse) = try await wrapped.send(urlRequest: urlRequest, delegate: delegate)
            let message = formatter.responseMessage(
                id: id,
                request: urlRequest,
                response: httpResponse,
                data: data,
                duration: ProcessInfo.processInfo.systemUptime - start
            )
            log(message, level: Self.level(forStatusCode: httpResponse.statusCode))
            return (data, httpResponse)
        } catch {
            let message = formatter.errorMessage(
                id: id,
                request: urlRequest,
                error: error,
                duration: ProcessInfo.processInfo.systemUptime - start
            )
            log(message, level: .fault)
            throw error
        }
    }

    static func level(forStatusCode statusCode: Int) -> OSLogType {
        switch statusCode {
        case 500...:
            .fault
        case 400 ..< 500:
            .error
        default:
            .debug
        }
    }

    private func log(_ message: String, level: OSLogType) {
        logger.log(level: level, "\(message, privacy: .public)")
    }
}

private final class RequestCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var value = 0

    func next() -> Int {
        lock.lock()
        defer { lock.unlock() }
        value += 1
        return value
    }
}
#endif
