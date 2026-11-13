import Foundation

/// A type that keeps OAuth credentials between launches of the app.
///
/// ``AuthenticatingTransport`` loads credentials from the store, saves rotated credentials after
/// a refresh and clears the store when a refresh fails.
@available(iOS 15.0.0, *)
@available(macOS 12.0, *)
public protocol OAuthCredentialsStore: Sendable {
    /// Loads the stored credentials. Returns `nil` when the store is empty.
    func load() async throws -> OAuthCredentials?

    /// Saves credentials. Replaces the credentials that the store holds.
    func save(_ credentials: OAuthCredentials) async throws

    /// Removes the stored credentials.
    func clear() async throws
}

/// A store that keeps the credentials in memory.
///
/// Use it in tests, previews and demos. The credentials are lost when the process stops.
@available(iOS 15.0.0, *)
@available(macOS 12.0, *)
public actor InMemoryOAuthCredentialsStore: OAuthCredentialsStore {
    private var credentials: OAuthCredentials?

    /// Creates a store.
    ///
    /// - Parameter credentials: The credentials that the store holds at the start.
    public init(credentials: OAuthCredentials? = nil) {
        self.credentials = credentials
    }

    public func load() -> OAuthCredentials? {
        credentials
    }

    public func save(_ credentials: OAuthCredentials) {
        self.credentials = credentials
    }

    public func clear() {
        credentials = nil
    }
}
