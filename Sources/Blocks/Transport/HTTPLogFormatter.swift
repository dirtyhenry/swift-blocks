#if canImport(OSLog)
import Foundation

/// Builds the log messages of `LoggingTransport`.
///
/// A message starts with a summary line. Details can follow: the body and the headers. Console.app shows the first
/// line of a message in the message column and the other lines in the detail pane.
///
/// The summaries are cheap to build. The details are not, thus `LoggingTransport` builds them only when the system
/// collects `debug` messages.
struct HTTPLogFormatter {
    /// The maximum size of a message, in UTF-8 bytes.
    ///
    /// The unified logging system cuts messages at approximately 1 KB.
    static let messageByteLimit = 1000

    /// The maximum size of a body to parse as JSON, in bytes.
    ///
    /// For a larger body, the formatter shows only the start of the text, because the message cut removes the rest.
    static let parsedBodyByteLimit = 64 * 1024

    /// The lowercased names of the header fields to redact.
    let redactedHeaderFields: Set<String>

    init(redactedHeaderFields: Set<String>) {
        self.redactedHeaderFields = Set(redactedHeaderFields.map { $0.lowercased() })
    }

    // MARK: - Requests

    /// Returns the summary and the details of a request.
    func requestMessage(id: Int, request: URLRequest) -> String {
        let body = request.httpBody ?? Data()
        let json = parseJSON(body)

        var summary = "→ #\(id) \(method(of: request)) \(url(of: request, redacted: false))"
        if let operationName = graphQLOperationName(of: request, json: json) {
            summary += " (\(operationName))"
        }

        let renderedBody: String? = if !body.isEmpty {
            render(body: body, json: json, contentType: request.value(forHTTPHeaderField: "Content-Type"))
        } else if request.httpBodyStream != nil {
            "<streamed body>"
        } else {
            nil
        }

        return message(
            summary: summary,
            details: details(body: renderedBody, headers: request.allHTTPHeaderFields ?? [:])
        )
    }

    // MARK: - Responses

    // swiftlint:disable function_parameter_count
    /// Returns the summary of a response.
    ///
    /// - Parameter redactsURL: Set to `true` to remove the query and the user info from the URL.
    func responseSummary(
        id: Int,
        request: URLRequest,
        response: HTTPURLResponse,
        byteCount: Int,
        duration: TimeInterval,
        redactsURL: Bool
    ) -> String {
        [
            "← #\(id) \(response.statusCode) \(method(of: request)) \(url(of: request, redacted: redactsURL))",
            Self.format(duration: duration),
            Self.format(byteCount: byteCount)
        ].joined(separator: " · ")
    }

    // swiftlint:enable function_parameter_count

    /// Returns the body and the headers of a response.
    func responseDetails(response: HTTPURLResponse, data: Data) -> String? {
        var headers: [String: String] = [:]
        for (name, value) in response.allHeaderFields {
            headers[String(describing: name)] = String(describing: value)
        }

        let renderedBody = data.isEmpty
            ? nil
            : render(body: data, json: parseJSON(data), contentType: response.value(forHTTPHeaderField: "Content-Type"))

        return details(body: renderedBody, headers: headers)
    }

    // MARK: - Errors

    /// Returns the summary of an error.
    ///
    /// - Parameter redactsURL: Set to `true` to remove the query and the user info from the URL.
    func errorSummary(id: Int, request: URLRequest, error: Error, duration: TimeInterval, redactsURL: Bool) -> String {
        [
            "← #\(id) ERROR \(method(of: request)) \(url(of: request, redacted: redactsURL))",
            Self.format(duration: duration),
            error.localizedDescription
        ].joined(separator: " · ")
    }

    // MARK: - Messages

    /// Returns one message with the summary and the details.
    func message(summary: String, details: String?) -> String {
        guard let details else {
            return truncate(summary)
        }

        return truncate(summary + "\n" + details)
    }

    /// Returns a message with the full URL and the details. Its first line refers to the request number.
    func detailsMessage(id: Int, request: URLRequest, details: String?) -> String {
        let head = "↳ #\(id) details\n\(url(of: request, redacted: false))"
        guard let details else {
            return truncate(head)
        }

        return truncate(head + "\n\n" + details)
    }

    // MARK: - Message Parts

    private func method(of request: URLRequest) -> String {
        request.httpMethod ?? "GET"
    }

    /// Returns the URL of the request. A redacted URL has no query, no fragment and no user info.
    private func url(of request: URLRequest, redacted: Bool) -> String {
        guard let url = request.url else {
            return "<no URL>"
        }

        guard redacted, var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return url.absoluteString
        }

        let hasQuery = components.query != nil
        components.query = nil
        components.fragment = nil
        components.user = nil
        components.password = nil
        return (components.string ?? "<no URL>") + (hasQuery ? "?…" : "")
    }

    private func graphQLOperationName(of request: URLRequest, json: Any?) -> String? {
        if let operationName = (json as? [String: Any])?["operationName"] as? String {
            return operationName
        }

        guard let url = request.url else {
            return nil
        }

        return URLComponents(url: url, resolvingAgainstBaseURL: true)?
            .queryItems?
            .first { $0.name == "operationName" }?
            .value
    }

    /// Puts the body before the headers, because a message can be too long. Then the cut removes headers first.
    private func details(body: String?, headers: [String: String]) -> String? {
        var sections: [String] = []
        if let body {
            sections.append(body)
        }

        let headerLines = headers
            .sorted { $0.key.lowercased() < $1.key.lowercased() }
            .map { name, value in
                "\(name): \(redactedHeaderFields.contains(name.lowercased()) ? "<redacted>" : value)"
            }
        if !headerLines.isEmpty {
            sections.append(headerLines.joined(separator: "\n"))
        }

        return sections.isEmpty ? nil : sections.joined(separator: "\n\n")
    }

    private func parseJSON(_ body: Data) -> Any? {
        guard !body.isEmpty, body.count <= Self.parsedBodyByteLimit else {
            return nil
        }

        return try? JSONSerialization.jsonObject(with: body)
    }

    private func render(body: Data, json: Any?, contentType: String?) -> String {
        if let json, let pretty = prettyJSON(json) {
            return pretty
        }

        if !Self.isBinary(contentType: contentType, body: body), let text = textPrefix(of: body) {
            return text
        }

        return "<\(Self.format(byteCount: body.count)) \(contentType ?? "binary data")>"
    }

    private func prettyJSON(_ object: Any) -> String? {
        guard
            object is [Any] || object is [String: Any],
            let prettyData = try? JSONSerialization.data(
                withJSONObject: object,
                options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            )
        else {
            return nil
        }

        return String(data: prettyData, encoding: .utf8)
    }

    /// Tells if a body is binary, from its content type or from a NUL byte at its start.
    static func isBinary(contentType: String?, body: Data) -> Bool {
        let binaryTypePrefixes = ["image/", "audio/", "video/", "font/", "application/octet-stream"]
        let binaryTypeFragments = ["protobuf", "zip", "pdf"]
        let type = contentType?.lowercased() ?? ""
        if binaryTypePrefixes.contains(where: type.hasPrefix) || binaryTypeFragments.contains(where: type.contains) {
            return true
        }

        return body.prefix(messageByteLimit).contains(0)
    }

    /// Decodes only the start of the body, because the message cut removes the rest.
    ///
    /// The prefix can end in the middle of a UTF-8 character. Thus, this function removes up to 3 bytes at the end.
    private func textPrefix(of body: Data) -> String? {
        let prefix = body.prefix(Self.messageByteLimit)
        let minimumCount = prefix.count == body.count ? prefix.count : max(prefix.count - 3, 1)
        for count in stride(from: prefix.count, through: minimumCount, by: -1) {
            if let text = String(data: prefix.prefix(count), encoding: .utf8) {
                return text
            }
        }

        return nil
    }

    private func truncate(_ message: String) -> String {
        guard message.utf8.count > Self.messageByteLimit else {
            return message
        }

        let marker = "\n… (truncated)"
        return utf8Prefix(message, maxLength: Self.messageByteLimit - marker.utf8.count) + marker
    }

    // MARK: - Units

    static func format(duration: TimeInterval) -> String {
        let milliseconds = Int((duration * 1000).rounded())
        if milliseconds < 1000 {
            return "\(milliseconds) ms"
        }

        return String(format: "%.2f s", duration)
    }

    static func format(byteCount: Int) -> String {
        if byteCount < 1024 {
            return "\(byteCount) B"
        }

        let kilobytes = (Double(byteCount) / 1024 * 10).rounded() / 10
        if kilobytes < 1024 {
            return String(format: "%.1f KB", kilobytes)
        }

        return String(format: "%.1f MB", Double(byteCount) / (1024 * 1024))
    }
}
#endif
