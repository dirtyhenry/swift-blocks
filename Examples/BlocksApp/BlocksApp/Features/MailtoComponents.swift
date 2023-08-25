import Foundation

struct MailtoComponents {
    var recipient: String?
    var subject: String?
    var body: String?

    init() {}

    var url: URL? {
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

    mutating func setToRecipient(_ recipient: String) {
        self.recipient = recipient
    }

    mutating func setSubject(_ subject: String) {
        self.subject = subject
    }

    mutating func setMessageBody(_ body: String) {
        self.body = body
    }
}
