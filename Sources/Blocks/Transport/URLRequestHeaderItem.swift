import Foundation

/// A structure representing an individual header item for a `URLRequest`.
public struct URLRequestHeaderItem {
    /// The name of the header.
    let name: String

    /// The value associated with the header.
    ///
    /// It can be nil if the header has no value.
    let value: String?

    /// Initializes a URLRequestHeaderItem with the specified name and value.
    ///
    /// - Parameters:
    ///   - name: The name of the header.
    ///   - value: The value associated with the header. It can be nil if the header has no value.
    public init(name: String, value: String?) {
        self.name = name
        self.value = value
    }
}

/// Convenience methods for creating common URLRequestHeaderItems.
public extension URLRequestHeaderItem {
    /// Creates a basic authentication header item with the specified username and password.
    ///
    /// - Parameters:
    ///   - username: The username for basic authentication.
    ///   - password: The password for basic authentication.
    /// - Returns: A URLRequestHeaderItem representing the basic authentication header.
    static func basicAuthentication(username: String, password: String) -> Self {
        let credentials = Data("\(username):\(password)".utf8)
            .base64EncodedString()

        return Self(name: "Authorization", value: "Basic \(credentials)")
    }
}

/// Extension for URLRequest to set custom header fields easily.
public extension URLRequest {
    /// Sets a custom HTTP header field using the provided URLRequestHeaderItem.
    ///
    /// - Parameter headerItem: The URLRequestHeaderItem containing the header name and value.
    mutating func setHTTPHeaderField(_ headerItem: URLRequestHeaderItem) {
        setValue(headerItem.value, forHTTPHeaderField: headerItem.name)
    }
}
