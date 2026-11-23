#if canImport(OSLog)
import Foundation

/// Builds the log messages of `LoggingTransport`.
///
/// Each entry has a summary line and optional details: the body and the headers. Console.app shows the first line of
/// a message in the message column and the other lines in the detail pane.
struct HTTPLogFormatter {
    /// The summary and the details of one request, response or error.
    struct Entry: Equatable {
        let summary: String
        let details: String?
    }

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

    func requestEntry(id: Int, request: URLRequest) -> Entry {
        let body = request.httpBody ?? Data()
        let json = parseJSON(body)

        var summary = "→ #\(id) \(method(of: request)) \(url(of: request))"
        if let operationName = (json as? [String: Any])?["operationName"] as? String {
            summary += " (\(operationName))"
        }

        let renderedBody: String? = if !body.isEmpty {
            render(body: body, json: json, contentType: request.value(forHTTPHeaderField: "Content-Type"))
        } else if request.httpBodyStream != nil {
            "<streamed body>"
        } else {
            nil
        }

        return Entry(
            summary: summary,
            details: details(body: renderedBody, headers: request.allHTTPHeaderFields ?? [:])
        )
    }

    func responseEntry(
        id: Int,
        request: URLRequest,
        response: HTTPURLResponse,
        data: Data,
        duration: TimeInterval
    ) -> Entry {
        let summary = [
            "← #\(id) \(response.statusCode) \(method(of: request)) \(url(of: request))",
            Self.format(duration: duration),
            Self.format(byteCount: data.count)
        ].joined(separator: " · ")

        var headers: [String: String] = [:]
        for (name, value) in response.allHeaderFields {
            headers[String(describing: name)] = String(describing: value)
        }

        let renderedBody = data.isEmpty
            ? nil
            : render(body: data, json: parseJSON(data), contentType: response.value(forHTTPHeaderField: "Content-Type"))

        return Entry(summary: summary, details: details(body: renderedBody, headers: headers))
    }

    func errorEntry(id: Int, request: URLRequest, error: Error, duration: TimeInterval) -> Entry {
        let summary = [
            "← #\(id) ERROR \(method(of: request)) \(url(of: request))",
            Self.format(duration: duration),
            error.localizedDescription
        ].joined(separator: " · ")

        return Entry(summary: summary, details: nil)
    }

    // MARK: - Messages

    /// Returns one message with the summary and the details.
    func message(for entry: Entry) -> String {
        guard let details = entry.details else {
            return truncate(entry.summary)
        }

        return truncate(entry.summary + "\n" + details)
    }

    /// Returns a message with the summary only.
    func summaryMessage(for entry: Entry) -> String {
        truncate(entry.summary)
    }

    /// Returns a message with the details only. Its first line refers to the request number.
    func detailsMessage(id: Int, details: String) -> String {
        truncate("↳ #\(id) details\n" + details)
    }

    // MARK: - Message Parts

    private func method(of request: URLRequest) -> String {
        request.httpMethod ?? "GET"
    }

    private func url(of request: URLRequest) -> String {
        request.url?.absoluteString ?? "<no URL>"
    }

    /// Puts the body before the headers, because a message can be too long. Then the cut removes headers first.
    private func details(body: String?, headers: [String: String]) -> String? {
        var sections: [String] = []
        if let body {
            sections.append(body)
        }

        let headerLines = headers
            .sorted { $0.key.localizedCaseInsensitiveCompare($1.key) == .orderedAscending }
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

        if let text = utf8Prefix(of: body) {
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

    /// Decodes only the start of the body, because the message cut removes the rest.
    ///
    /// The prefix can end in the middle of a UTF-8 character. Thus, this function removes up to 3 bytes at the end.
    private func utf8Prefix(of body: Data) -> String? {
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
        return message.prefix(utf8ByteCount: Self.messageByteLimit - marker.utf8.count) + marker
    }

    // MARK: - Units

    static func format(duration: TimeInterval) -> String {
        if duration < 1 {
            return "\(Int((duration * 1000).rounded())) ms"
        }

        return String(format: "%.2f s", duration)
    }

    static func format(byteCount: Int) -> String {
        if byteCount < 1024 {
            return "\(byteCount) B"
        }

        if byteCount < 1024 * 1024 {
            return String(format: "%.1f KB", Double(byteCount) / 1024)
        }

        return String(format: "%.1f MB", Double(byteCount) / (1024 * 1024))
    }
}

private extension String {
    /// Returns the longest prefix that fits in the given number of UTF-8 bytes, without a split character.
    func prefix(utf8ByteCount maxByteCount: Int) -> Substring {
        var byteCount = 0
        var end = startIndex
        while end < endIndex {
            let characterByteCount = self[end].utf8.count
            if byteCount + characterByteCount > maxByteCount {
                break
            }
            byteCount += characterByteCount
            end = index(after: end)
        }

        return self[..<end]
    }
}
#endif
