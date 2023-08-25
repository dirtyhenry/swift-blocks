import Foundation

public struct MailtoComponents {
    public var recipient: String?
    public var subject: String?
    public var body: String?

    public init() {}

    public var url: URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        if let recipient {
            components.path = recipient
        }
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body?
                .components(separatedBy: .newlines)
                .joined(separator: "\r\n"))
        ].filter { $0.value != nil }

        return components.url
    }

    // MARK: MFMailComposeViewController-like API

    public mutating func setToRecipient(_ recipient: String) {
        self.recipient = recipient
    }

    public mutating func setSubject(_ subject: String) {
        self.subject = subject
    }

    public mutating func setMessageBody(_ body: String) {
        self.body = body
    }
}
