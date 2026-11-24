#if canImport(CryptoKit)
import Foundation
#if canImport(AuthenticationServices) && (os(iOS) || os(macOS))
import AuthenticationServices
#endif
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// A session that runs an OAuth 2.0 authorization code flow with PKCE in a browser.
///
/// The session builds the authorization URL, opens it in `ASWebAuthenticationSession` and reads
/// the authorization code from the callback URL. The caller exchanges the code for tokens with
/// the provider.
///
/// See <doc:OAuth> for a complete example.
public struct OAuthAuthorizationSession: Sendable {
    /// The parameters of the authorization request.
    public struct Configuration: Sendable {
        /// The URL of the authorization endpoint of the provider.
        public var authorizationEndpoint: URL

        /// The client ID that the provider gave to the app.
        public var clientID: String

        /// The scopes that the app requests.
        public var scopes: [String]

        /// The name of the query parameter that carries the scopes. The default is `scope`.
        ///
        /// Some providers use another name. For example, Slack uses `user_scope` for user tokens.
        public var scopeParameterName: String

        /// The string that separates the scopes. The default is a space.
        public var scopeSeparator: String

        /// The URL that the provider calls back with the code. It must use a custom URL scheme.
        public var redirectURI: URL

        /// Query items that the session adds to the authorization URL.
        public var additionalQueryItems: [URLQueryItem]

        /// Tells if the browser session shares cookies with the user's browser. The default is
        /// `false`: the session shares cookies.
        public var prefersEphemeralWebBrowserSession: Bool

        /// Creates a configuration.
        ///
        /// - Parameters:
        ///   - authorizationEndpoint: The URL of the authorization endpoint of the provider.
        ///   - clientID: The client ID that the provider gave to the app.
        ///   - scopes: The scopes that the app requests.
        ///   - scopeParameterName: The name of the query parameter that carries the scopes.
        ///   - scopeSeparator: The string that separates the scopes.
        ///   - redirectURI: The URL that the provider calls back with the code.
        ///   - additionalQueryItems: Query items that the session adds to the authorization URL.
        ///   - prefersEphemeralWebBrowserSession: Tells if the browser session shares cookies.
        public init(
            authorizationEndpoint: URL,
            clientID: String,
            scopes: [String],
            scopeParameterName: String = "scope",
            scopeSeparator: String = " ",
            redirectURI: URL,
            additionalQueryItems: [URLQueryItem] = [],
            prefersEphemeralWebBrowserSession: Bool = false
        ) {
            self.authorizationEndpoint = authorizationEndpoint
            self.clientID = clientID
            self.scopes = scopes
            self.scopeParameterName = scopeParameterName
            self.scopeSeparator = scopeSeparator
            self.redirectURI = redirectURI
            self.additionalQueryItems = additionalQueryItems
            self.prefersEphemeralWebBrowserSession = prefersEphemeralWebBrowserSession
        }
    }

    /// An authorization request that is ready to open in a browser.
    public struct Request: Equatable, Sendable {
        /// The authorization URL to open.
        public let url: URL

        /// The state that the callback must return.
        public let state: String

        /// The PKCE code verifier that the token exchange needs.
        public let codeVerifier: String
    }

    /// The result of a successful authorization.
    public struct Result: Equatable, Sendable {
        /// The authorization code to exchange for tokens.
        public let code: String

        /// The PKCE code verifier to send with the code.
        public let codeVerifier: String

        /// Creates a result.
        ///
        /// - Parameters:
        ///   - code: The authorization code to exchange for tokens.
        ///   - codeVerifier: The PKCE code verifier to send with the code.
        public init(code: String, codeVerifier: String) {
            self.code = code
            self.codeVerifier = codeVerifier
        }
    }

    /// The parameters of the authorization request.
    public let configuration: Configuration

    /// Creates a session.
    ///
    /// - Parameter configuration: The parameters of the authorization request.
    public init(configuration: Configuration) {
        self.configuration = configuration
    }

    // MARK: - Build the request

    /// Builds the authorization request with new PKCE seeds and a new random state.
    ///
    /// - Returns: The request to open in a browser.
    public func makeRequest() throws -> Request {
        try Self.makeRequest(
            configuration: configuration,
            seeds: PKCE.ClientSeeds(),
            state: Self.makeState()
        )
    }

    /// Builds the authorization request.
    ///
    /// - Parameters:
    ///   - configuration: The parameters of the authorization request.
    ///   - seeds: The PKCE seeds.
    ///   - state: The state that the callback must return.
    /// - Returns: The request to open in a browser.
    public static func makeRequest(
        configuration: Configuration,
        seeds: PKCE.ClientSeeds,
        state: String
    ) throws -> Request {
        guard var components = URLComponents(
            url: configuration.authorizationEndpoint,
            resolvingAgainstBaseURL: false
        ) else {
            throw TransportError.unmetURLComponentsRequirements
        }

        var queryItems = components.queryItems ?? []
        try queryItems += [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: configuration.clientID),
            URLQueryItem(name: "redirect_uri", value: configuration.redirectURI.absoluteString),
            URLQueryItem(
                name: configuration.scopeParameterName,
                value: configuration.scopes.joined(separator: configuration.scopeSeparator)
            ),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "code_challenge", value: seeds.codeChallenge()),
            URLQueryItem(name: "code_challenge_method", value: "S256")
        ]
        queryItems += configuration.additionalQueryItems
        components.queryItems = queryItems

        guard let url = components.url else {
            throw TransportError.unmetURLComponentsRequirements
        }

        return Request(url: url, state: state, codeVerifier: seeds.codeVerifier)
    }

    static func makeState() throws -> String {
        let octets = try SecurityUtils.generateCryptographicallySecureRandomOctets(count: 16)
        return DataFormatter.base64URLString(from: Data(octets))
    }

    // MARK: - Read the callback

    /// Reads the authorization code from the callback URL.
    ///
    /// - Parameters:
    ///   - url: The callback URL that the provider opened.
    ///   - expectedState: The state of the request.
    ///   - codeVerifier: The PKCE code verifier of the request.
    /// - Returns: The authorization code and the code verifier.
    /// - Throws: ``OAuthAuthorizationError``.
    public static func parseCallback(url: URL, expectedState: String, codeVerifier: String) throws -> Result {
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        func value(_ name: String) -> String? {
            queryItems.first { $0.name == name }?.value
        }

        guard value("state") == expectedState else {
            throw OAuthAuthorizationError.stateMismatch
        }

        if let errorCode = value("error") {
            throw OAuthAuthorizationError.providerError(code: errorCode, description: value("error_description"))
        }

        guard let code = value("code"), !code.isEmpty else {
            throw OAuthAuthorizationError.missingCode
        }

        return Result(code: code, codeVerifier: codeVerifier)
    }

    #if canImport(AuthenticationServices) && (os(iOS) || os(macOS))

    // MARK: - Run the flow in a browser

    /// A closure that gives the window that presents the browser.
    public typealias PresentationAnchorProvider = @MainActor @Sendable () -> ASPresentationAnchor

    /// Opens the authorization URL in a browser and waits for the callback.
    ///
    /// - Parameter presentationAnchor: The window that presents the browser. The default is the
    ///   key window of the app.
    /// - Returns: The authorization code and the code verifier.
    /// - Throws: ``OAuthAuthorizationError``. ``OAuthAuthorizationError/cancelled`` when the user
    ///   closes the browser.
    @MainActor
    public func authorize(
        presentationAnchor: @escaping PresentationAnchorProvider = defaultPresentationAnchor
    ) async throws -> Result {
        let request = try makeRequest()
        let callbackURL = try await Self.openInBrowser(
            url: request.url,
            callbackURLScheme: configuration.redirectURI.scheme,
            prefersEphemeralWebBrowserSession: configuration.prefersEphemeralWebBrowserSession,
            presentationAnchor: presentationAnchor
        )
        return try Self.parseCallback(
            url: callbackURL,
            expectedState: request.state,
            codeVerifier: request.codeVerifier
        )
    }

    @MainActor
    private static func openInBrowser(
        url: URL,
        callbackURLScheme: String?,
        prefersEphemeralWebBrowserSession: Bool,
        presentationAnchor: @escaping PresentationAnchorProvider
    ) async throws -> URL {
        let runner = BrowserSessionRunner(anchor: presentationAnchor)
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                runner.start(
                    url: url,
                    callbackURLScheme: callbackURLScheme,
                    prefersEphemeralWebBrowserSession: prefersEphemeralWebBrowserSession,
                    continuation: continuation
                )
            }
        } onCancel: {
            Task { @MainActor in
                runner.cancel()
            }
        }
    }

    /// Maps an error of `ASWebAuthenticationSession` to an ``OAuthAuthorizationError``.
    ///
    /// - Parameter error: The error of the session.
    /// - Returns: ``OAuthAuthorizationError/cancelled`` when the user closed the browser.
    static func mapSessionError(_ error: Error) -> OAuthAuthorizationError {
        if let sessionError = error as? ASWebAuthenticationSessionError, sessionError.code == .canceledLogin {
            return .cancelled
        }
        return .sessionFailed(error)
    }

    /// Finds the key window of the app.
    ///
    /// - Returns: The key window, or a new window when the app has no key window.
    @MainActor
    public static func defaultPresentationAnchor() -> ASPresentationAnchor {
        #if os(iOS)
        let keyWindow = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .sorted { $0.activationState.rawValue < $1.activationState.rawValue }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }
        return keyWindow ?? ASPresentationAnchor()
        #else
        return NSApplication.shared.keyWindow ?? NSApplication.shared.windows.first ?? ASPresentationAnchor()
        #endif
    }

    /// Owns the browser session and the continuation that waits for the callback.
    @MainActor
    private final class BrowserSessionRunner: NSObject, ASWebAuthenticationPresentationContextProviding {
        private let anchor: PresentationAnchorProvider
        private var session: ASWebAuthenticationSession?
        private var continuation: CheckedContinuation<URL, Error>?

        init(anchor: @escaping PresentationAnchorProvider) {
            self.anchor = anchor
        }

        func start(
            url: URL,
            callbackURLScheme: String?,
            prefersEphemeralWebBrowserSession: Bool,
            continuation: CheckedContinuation<URL, Error>
        ) {
            self.continuation = continuation
            guard !Task.isCancelled else {
                complete(callbackURL: nil, error: OAuthAuthorizationError.cancelled)
                return
            }

            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: callbackURLScheme
            ) { [weak self] callbackURL, error in
                Task { @MainActor in
                    self?.complete(callbackURL: callbackURL, error: error)
                }
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = prefersEphemeralWebBrowserSession
            self.session = session

            if !session.start() {
                complete(callbackURL: nil, error: nil)
            }
        }

        func cancel() {
            session?.cancel()
        }

        nonisolated func presentationAnchor(for _: ASWebAuthenticationSession) -> ASPresentationAnchor {
            MainActor.assumeIsolated {
                anchor()
            }
        }

        private func complete(callbackURL: URL?, error: Error?) {
            guard let continuation else { return }
            self.continuation = nil
            session = nil
            if let authorizationError = error as? OAuthAuthorizationError {
                continuation.resume(throwing: authorizationError)
            } else if let error {
                continuation.resume(throwing: OAuthAuthorizationSession.mapSessionError(error))
            } else if let callbackURL {
                continuation.resume(returning: callbackURL)
            } else {
                continuation.resume(throwing: OAuthAuthorizationError.sessionFailed(
                    SimpleMessageError(message: "The browser session did not start.")
                ))
            }
        }
    }
    #endif
}

/// An error met when the user authorizes the app.
public enum OAuthAuthorizationError: Error {
    /// The user closed the browser before the provider called back.
    case cancelled

    /// The `state` of the callback is not the `state` of the request.
    case stateMismatch

    /// The provider called back with an `error` parameter.
    case providerError(code: String, description: String?)

    /// The callback has no `code` parameter.
    case missingCode

    /// The browser session failed.
    case sessionFailed(Error)
}

extension OAuthAuthorizationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .cancelled:
            "The user cancelled the authorization."
        case .stateMismatch:
            "The authorization callback has a wrong state."
        case let .providerError(code, description):
            if let description {
                "The provider refused the authorization: \(code). \(description)"
            } else {
                "The provider refused the authorization: \(code)."
            }
        case .missingCode:
            "The authorization callback has no code."
        case let .sessionFailed(error):
            "The browser session failed: \(error.localizedDescription)"
        }
    }
}
#endif
