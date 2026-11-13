import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// A transport that authenticates requests with an OAuth 2.0 bearer token.
///
/// The transport adds an `Authorization: Bearer <access token>` header to each request. It
/// refreshes the credentials before a request when the access token is expired or about to
/// expire. It refreshes the credentials one more time, and sends the request again one time, when
/// the response says that the token is expired.
///
/// Concurrent requests share one refresh. The transport saves the new credentials in the
/// ``OAuthCredentialsStore`` after each refresh. When the refresh fails, the transport clears the
/// store and throws ``ReauthenticationRequiredError``.
///
/// See <doc:OAuth> for a complete example.
@available(iOS 15.0.0, *)
@available(macOS 12.0, *)
public final class AuthenticatingTransport: Transport {
    /// A closure that gets new credentials from the provider.
    ///
    /// The closure receives the refresh token. It returns the new credentials.
    public typealias Refresh = @Sendable (_ refreshToken: String) async throws -> OAuthCredentials

    /// A closure that tells if a response says that the access token is expired or invalid.
    public typealias ExpiredTokenDetector = @Sendable (_ data: Data, _ response: HTTPURLResponse) -> Bool

    let wrapped: Transport
    let coordinator: OAuthCredentialsCoordinator
    let isTokenExpired: ExpiredTokenDetector

    /// Creates a transport.
    ///
    /// - Parameters:
    ///   - wrapping: The transport that sends the requests.
    ///   - store: The store that keeps the credentials.
    ///   - leeway: The number of seconds before the expiry date when the transport refreshes the
    ///     credentials. The default is 60 seconds.
    ///   - isTokenExpired: A closure that tells if a response says that the token is expired. The
    ///     default is ``unauthorizedStatusCode(data:response:)``.
    ///   - now: A closure that gives the current date. Replace it in tests.
    ///   - refresh: The closure that gets new credentials from the provider.
    public init(
        wrapping: Transport,
        store: OAuthCredentialsStore,
        leeway: TimeInterval = 60,
        isTokenExpired: @escaping ExpiredTokenDetector = AuthenticatingTransport.unauthorizedStatusCode,
        now: @Sendable @escaping () -> Date = Date.init,
        refresh: @escaping Refresh
    ) {
        wrapped = wrapping
        coordinator = OAuthCredentialsCoordinator(store: store, leeway: leeway, now: now, refresh: refresh)
        self.isTokenExpired = isTokenExpired
    }

    /// Sends a request with a bearer token.
    ///
    /// - Parameters:
    ///   - urlRequest: The request to send.
    ///   - delegate: An optional delegate for the URL session task.
    /// - Returns: The response data and the HTTP response.
    /// - Throws: ``ReauthenticationRequiredError`` when there are no usable credentials, or the
    ///   error of the wrapped transport.
    public func send(
        urlRequest: URLRequest,
        delegate: URLSessionTaskDelegate?
    ) async throws -> (Data, HTTPURLResponse) {
        let credentials = try await coordinator.validCredentials()
        let (data, response) = try await send(urlRequest, with: credentials, delegate: delegate)

        guard isTokenExpired(data, response) else {
            return (data, response)
        }

        let newCredentials = try await coordinator.refreshedCredentials(replacing: credentials)
        return try await send(urlRequest, with: newCredentials, delegate: delegate)
    }

    private func send(
        _ urlRequest: URLRequest,
        with credentials: OAuthCredentials,
        delegate: URLSessionTaskDelegate?
    ) async throws -> (Data, HTTPURLResponse) {
        var authenticatedRequest = urlRequest
        authenticatedRequest.setHTTPHeaderField(.bearerAuthentication(token: credentials.accessToken))
        return try await wrapped.send(urlRequest: authenticatedRequest, delegate: delegate)
    }

    // MARK: - Expired token detectors

    /// Tells that the token is expired when the status code is 401.
    ///
    /// - Parameters:
    ///   - data: The response data. Not used.
    ///   - response: The HTTP response.
    /// - Returns: `true` when the status code is 401.
    @Sendable
    public static func unauthorizedStatusCode(data _: Data, response: HTTPURLResponse) -> Bool {
        response.statusCode == 401
    }
}

/// An error that tells that the user must authorize the app again.
///
/// ``AuthenticatingTransport`` throws this error when it cannot get valid credentials. When the
/// reason is a failed refresh, the transport has cleared the store before it throws.
public struct ReauthenticationRequiredError: Error {
    /// The reason why the transport cannot get valid credentials.
    public enum Reason: Sendable {
        /// The store has no credentials.
        case missingCredentials

        /// The access token is expired and the credentials have no refresh token.
        case missingRefreshToken

        /// The refresh closure threw an error.
        case refreshFailed(Error)
    }

    /// The reason why the transport cannot get valid credentials.
    public let reason: Reason

    /// Creates an error.
    ///
    /// - Parameter reason: The reason why the transport cannot get valid credentials.
    public init(reason: Reason) {
        self.reason = reason
    }
}

extension ReauthenticationRequiredError: LocalizedError {
    public var errorDescription: String? {
        switch reason {
        case .missingCredentials:
            "Authentication is required: no credentials are stored."
        case .missingRefreshToken:
            "Authentication is required: the access token is expired and there is no refresh token."
        case let .refreshFailed(error):
            "Authentication is required: the refresh failed (\(error.localizedDescription))."
        }
    }
}

/// An actor that holds the credentials and shares one refresh between concurrent requests.
@available(iOS 15.0.0, *)
@available(macOS 12.0, *)
actor OAuthCredentialsCoordinator {
    private let store: OAuthCredentialsStore
    private let leeway: TimeInterval
    private let now: @Sendable () -> Date
    private let refresh: AuthenticatingTransport.Refresh

    private var cached: OAuthCredentials?
    private var hasLoaded = false
    private var inFlightRefresh: Task<OAuthCredentials, Error>?

    init(
        store: OAuthCredentialsStore,
        leeway: TimeInterval,
        now: @Sendable @escaping () -> Date,
        refresh: @escaping AuthenticatingTransport.Refresh
    ) {
        self.store = store
        self.leeway = leeway
        self.now = now
        self.refresh = refresh
    }

    /// Returns credentials whose access token is valid for at least `leeway` seconds.
    func validCredentials() async throws -> OAuthCredentials {
        let credentials = try await currentCredentials()

        guard credentials.isExpired(at: now().addingTimeInterval(leeway)) else {
            return credentials
        }

        return try await refreshedCredentials(replacing: credentials)
    }

    /// Returns new credentials. Shares one refresh between concurrent callers.
    ///
    /// When another caller has already replaced `stale`, returns the current credentials without
    /// a new refresh.
    func refreshedCredentials(replacing stale: OAuthCredentials) async throws -> OAuthCredentials {
        if let cached, cached.accessToken != stale.accessToken {
            return cached
        }

        if let inFlightRefresh {
            return try await inFlightRefresh.value
        }

        guard let refreshToken = stale.refreshToken else {
            throw ReauthenticationRequiredError(reason: .missingRefreshToken)
        }

        let task = Task<OAuthCredentials, Error> {
            defer { inFlightRefresh = nil }
            do {
                let newCredentials = try await refresh(refreshToken)
                try await store.save(newCredentials)
                cached = newCredentials
                return newCredentials
            } catch {
                cached = nil
                try? await store.clear()
                throw ReauthenticationRequiredError(reason: .refreshFailed(error))
            }
        }
        inFlightRefresh = task
        return try await task.value
    }

    private func currentCredentials() async throws -> OAuthCredentials {
        if !hasLoaded {
            cached = try await store.load()
            hasLoaded = true
        }

        guard let cached else {
            throw ReauthenticationRequiredError(reason: .missingCredentials)
        }

        return cached
    }
}
