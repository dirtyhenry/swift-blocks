import Foundation

/// Represents components for creating a `mailto` URL, allowing you to compose email messages.
public struct MailtoComponents {
    // MARK: - Accessing Components

    /// The email address of the recipient.
    public var recipient: String?

    /// The subject of the email.
    public var subject: String?

    /// The body of the email.
    public var body: String?

    // MARK: - Creating Mailto Components

    /// Initializes an empty `MailtoComponents` instance.
    public init() {}

    // MARK: - Getting the URL

    /// A URL created from the components.
    ///
    /// - Returns: A `mailto` URL or `nil` if the components are insufficient.
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

    // MARK: - MFMailComposeViewController-like API

    /// Sets the email address of the recipient.
    ///
    /// - Parameter recipient: The email address of the recipient.
    public mutating func setToRecipient(_ recipient: String) {
        self.recipient = recipient
    }

    /// Sets the subject of the email.
    ///
    /// - Parameter subject: The subject of the email.
    public mutating func setSubject(_ subject: String) {
        self.subject = subject
    }

    /// Sets the body of the email.
    ///
    /// - Parameter body: The body of the email.
    public mutating func setMessageBody(_ body: String) {
        self.body = body
    }
}

// This conformance can be useful to work with `swift-composable-architecture`.
extension MailtoComponents: Equatable {}
