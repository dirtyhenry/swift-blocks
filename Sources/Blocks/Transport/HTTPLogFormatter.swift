#if canImport(OSLog)
import Foundation

/// Builds the log messages of `LoggingTransport`.
///
/// The first line of each message is a summary. Console.app shows it in the message column. The other lines
/// contain the body and the headers. Console.app shows them in the detail pane.
struct HTTPLogFormatter {
    /// The maximum size of a message, in UTF-8 bytes.
    ///
    /// The unified logging system cuts messages at approximately 1 KB.
    static let messageByteLimit = 1000

    /// The lowercased names of the header fields to redact.
    let redactedHeaderFields: Set<String>

    init(redactedHeaderFields: Set<String>) {
        self.redactedHeaderFields = Set(redactedHeaderFields.map { $0.lowercased() })
    }

    func requestMessage(id: Int, request: URLRequest) -> String {
        var summary = "→ #\(id) \(method(of: request)) \(url(of: request))"
        if let operationName = graphQLOperationName(of: request) {
            summary += " (\(operationName))"
        }

        return message(
            summary: summary,
            headers: request.allHTTPHeaderFields ?? [:],
            body: request.httpBody ?? Data(),
            contentType: request.value(forHTTPHeaderField: "Content-Type")
        )
    }

    func responseMessage(
        id: Int,
        request: URLRequest,
        response: HTTPURLResponse,
        data: Data,
        duration: TimeInterval
    ) -> String {
        let summary = [
            "← #\(id) \(response.statusCode) \(method(of: request)) \(url(of: request))",
            Self.format(duration: duration),
            Self.format(byteCount: data.count)
        ].joined(separator: " · ")

        var headers: [String: String] = [:]
        for (name, value) in response.allHeaderFields {
            headers[String(describing: name)] = String(describing: value)
        }

        return message(
            summary: summary,
            headers: headers,
            body: data,
            contentType: response.value(forHTTPHeaderField: "Content-Type")
        )
    }

    func errorMessage(id: Int, request: URLRequest, error: Error, duration: TimeInterval) -> String {
        let summary = [
            "← #\(id) ERROR \(method(of: request)) \(url(of: request))",
            Self.format(duration: duration),
            error.localizedDescription
        ].joined(separator: " · ")

        return truncate(summary)
    }

    // MARK: - Message Parts

    private func method(of request: URLRequest) -> String {
        request.httpMethod ?? "GET"
    }

    private func url(of request: URLRequest) -> String {
        request.url?.absoluteString ?? "<no URL>"
    }

    private func graphQLOperationName(of request: URLRequest) -> String? {
        guard
            let body = request.httpBody,
            let object = try? JSONSerialization.jsonObject(with: body),
            let dictionary = object as? [String: Any]
        else {
            return nil
        }

        return dictionary["operationName"] as? String
    }

    /// Puts the body before the headers, because a message can be too long. Then the cut removes headers first.
    private func message(summary: String, headers: [String: String], body: Data, contentType: String?) -> String {
        var sections: [String] = []
        if !body.isEmpty {
            sections.append(render(body: body, contentType: contentType))
        }

        let headerLines = headers
            .sorted { $0.key.localizedCaseInsensitiveCompare($1.key) == .orderedAscending }
            .map { name, value in
                "\(name): \(redactedHeaderFields.contains(name.lowercased()) ? "<redacted>" : value)"
            }
        if !headerLines.isEmpty {
            sections.append(headerLines.joined(separator: "\n"))
        }

        guard !sections.isEmpty else {
            return truncate(summary)
        }

        return truncate(summary + "\n" + sections.joined(separator: "\n\n"))
    }

    private func render(body: Data, contentType: String?) -> String {
        if let pretty = prettyJSON(body) {
            return pretty
        }

        if let text = String(data: body, encoding: .utf8) {
            return text
        }

        return "<\(Self.format(byteCount: body.count)) \(contentType ?? "binary data")>"
    }

    private func prettyJSON(_ body: Data) -> String? {
        guard
            let object = try? JSONSerialization.jsonObject(with: body),
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
