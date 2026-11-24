import Foundation

/// The tokens that an OAuth 2.0 provider gives to a client.
///
/// ``AuthenticatingTransport`` reads the access token to authenticate requests. It uses the
/// refresh token to get new credentials when the access token expires.
public struct OAuthCredentials: Codable, Equatable, Hashable, Sendable {
    /// The token that authenticates the requests.
    public let accessToken: String

    /// The date when the access token expires. `nil` when the provider gives no expiry date.
    public let expiresAt: Date?

    /// The token that gets new credentials. `nil` when the provider gives no refresh token.
    public let refreshToken: String?

    /// Creates credentials.
    ///
    /// - Parameters:
    ///   - accessToken: The token that authenticates the requests.
    ///   - expiresAt: The date when the access token expires.
    ///   - refreshToken: The token that gets new credentials.
    public init(accessToken: String, expiresAt: Date? = nil, refreshToken: String? = nil) {
        self.accessToken = accessToken
        self.expiresAt = expiresAt
        self.refreshToken = refreshToken
    }

    /// Tells if the access token expires before a date.
    ///
    /// - Parameter date: The date to compare with the expiry date.
    /// - Returns: `true` when the access token has an expiry date that is not after `date`.
    public func isExpired(at date: Date) -> Bool {
        guard let expiresAt else { return false }
        return expiresAt <= date
    }
}
