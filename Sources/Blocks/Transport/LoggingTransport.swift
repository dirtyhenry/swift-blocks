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
/// summary, with no query and no user info in the URL. A second message with the `debug` level contains the full URL,
/// the body and the headers.
///
/// The wrapper builds the bodies and the headers only when the system collects `debug` messages. For example, when
/// Console.app streams the logs.
///
/// The unified logging system cuts messages at approximately 1 KB. Thus, this wrapper cuts long messages. It writes
/// the body before the headers, thus the cut removes the headers first.
///
/// The wrapper also writes one signpost interval for each request. Use Instruments to see the intervals as a waterfall
/// of the network activity. The intervals have the name `Request`, and the subsystem and the category of the logs:
///
/// ```
/// #12 POST https://example.com/graphql (SignIn)
/// 200 · 1.2 KB
/// ```
///
/// Instruments stores the intervals in trace files. Thus, the URLs of the intervals show no user info, and `?…` replaces
/// the query.
/// Console.app does not show signposts.
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
    let signposter: OSSignposter
    let formatter: HTTPLogFormatter
    private static let counter = RequestCounter()
    private static let signpostName: StaticString = "Request"

    public init(
        wrapping: Transport,
        subsystem: String,
        category: String = "Networking",
        configuration: Configuration = .init()
    ) {
        wrapped = wrapping
        logger = Logger(subsystem: subsystem, category: category)
        signposter = OSSignposter(logger: logger)
        formatter = HTTPLogFormatter(redactedHeaderFields: configuration.redactedHeaderFields)
    }

    public func send(
        urlRequest: URLRequest,
        delegate: URLSessionTaskDelegate?
    ) async throws -> (Data, HTTPURLResponse) {
        let id = Self.counter.next()
        let formatter = formatter
        logger.debug("\(formatter.requestMessage(id: id, request: urlRequest), privacy: .public)")
        let signpostState = signposter.beginInterval(
            Self.signpostName,
            id: signposter.makeSignpostID(),
            "\(formatter.signpostBeginMessage(id: id, request: urlRequest), privacy: .public)"
        )

        let start = ProcessInfo.processInfo.systemUptime
        do {
            let (data, httpResponse) = try await wrapped.send(urlRequest: urlRequest, delegate: delegate)
            let duration = ProcessInfo.processInfo.systemUptime - start
            signposter.endInterval(
                Self.signpostName,
                signpostState,
                "\(formatter.signpostEndMessage(response: httpResponse, byteCount: data.count), privacy: .public)"
            )
            log(
                level: Self.level(forStatusCode: httpResponse.statusCode),
                id: id,
                request: urlRequest,
                summary: { redactsURL in
                    formatter.responseSummary(
                        id: id,
                        request: urlRequest,
                        response: httpResponse,
                        byteCount: data.count,
                        duration: duration,
                        redactsURL: redactsURL
                    )
                },
                details: { formatter.responseDetails(response: httpResponse, data: data) }
            )
            return (data, httpResponse)
        } catch {
            let duration = ProcessInfo.processInfo.systemUptime - start
            signposter.endInterval(
                Self.signpostName,
                signpostState,
                "\(formatter.signpostEndMessage(error: error), privacy: .public)"
            )
            log(
                level: Self.level(for: error),
                id: id,
                request: urlRequest,
                summary: { redactsURL in
                    formatter.errorSummary(
                        id: id,
                        request: urlRequest,
                        error: error,
                        duration: duration,
                        redactsURL: redactsURL
                    )
                },
                details: { nil }
            )
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
    /// The system stores `error` and `fault` messages on disk, but not `debug` messages. Thus, the details and the
    /// full URL do not go to the disk.
    ///
    /// The logger calls the `details` closure only when the system collects `debug` messages.
    private func log(
        level: OSLogType,
        id: Int,
        request: URLRequest,
        summary: @escaping (_ redactsURL: Bool) -> String,
        details: @escaping () -> String?
    ) {
        let formatter = formatter
        guard level != .debug else {
            logger.debug("\(formatter.message(summary: summary(false), details: details()), privacy: .public)")
            return
        }

        logger.log(level: level, "\(formatter.message(summary: summary(true), details: nil), privacy: .public)")
        logger.debug("\(formatter.detailsMessage(id: id, request: request, details: details()), privacy: .public)")
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
