#if canImport(OSLog)
import Foundation
import OSLog

/// A transport wrapper that logs network activity to the unified logging system.
///
/// Use this wrapper **for debug purposes only**. It writes requests and responses to the console with a `public`
/// privacy.
///
/// Each request gets a number, for example `#12`. The request and its response show the same number. Use this number
/// to find the response of a request in Console.app. All the instances in a process share the numbers.
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
/// - Status codes from 500 and thrown errors use the `fault` level. A cancellation uses the `debug` level.
///
/// The system stores `error` and `fault` messages on disk. Thus, for these levels, the message contains only the
/// summary. A second message with the `debug` level contains the body and the headers.
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
    private static let counter = RequestCounter()

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
        let id = Self.counter.next()
        log(formatter.requestEntry(id: id, request: urlRequest), id: id, level: .debug)

        let start = ProcessInfo.processInfo.systemUptime
        do {
            let (data, httpResponse) = try await wrapped.send(urlRequest: urlRequest, delegate: delegate)
            let entry = formatter.responseEntry(
                id: id,
                request: urlRequest,
                response: httpResponse,
                data: data,
                duration: ProcessInfo.processInfo.systemUptime - start
            )
            log(entry, id: id, level: Self.level(forStatusCode: httpResponse.statusCode))
            return (data, httpResponse)
        } catch {
            let entry = formatter.errorEntry(
                id: id,
                request: urlRequest,
                error: error,
                duration: ProcessInfo.processInfo.systemUptime - start
            )
            log(entry, id: id, level: Self.level(for: error))
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

    static func level(for error: Error) -> OSLogType {
        if error is CancellationError || (error as? URLError)?.code == .cancelled {
            return .debug
        }

        return .fault
    }

    /// Logs the details in a separate `debug` message when the level is higher than `debug`.
    ///
    /// The system stores `error` and `fault` messages on disk, but not `debug` messages. Thus, the body and the
    /// headers do not go to the disk.
    private func log(_ entry: HTTPLogFormatter.Entry, id: Int, level: OSLogType) {
        guard level != .debug else {
            log(formatter.message(for: entry), level: .debug)
            return
        }

        log(formatter.summaryMessage(for: entry), level: level)
        if let details = entry.details {
            log(formatter.detailsMessage(id: id, details: details), level: .debug)
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
