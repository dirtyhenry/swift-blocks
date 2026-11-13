import AuthenticationServices
import Blocks
import SwiftUI

/// A transport that plays the role of an API server.
///
/// It answers with the `Authorization` header of the request. When the bearer token is in the
/// revoked list, it answers with a Slack-like `token_expired` body.
actor FakeAPITransport: Transport {
    private(set) var revokedTokens: Set<String> = []

    func revoke(_ token: String) {
        revokedTokens.insert(token)
    }

    nonisolated func send(
        urlRequest: URLRequest,
        delegate _: URLSessionTaskDelegate?
    ) async throws -> (Data, HTTPURLResponse) {
        try await answer(urlRequest)
    }

    private func answer(_ urlRequest: URLRequest) throws -> (Data, HTTPURLResponse) {
        let authorization = urlRequest.value(forHTTPHeaderField: "Authorization") ?? "<none>"
        let token = authorization.replacingOccurrences(of: "Bearer ", with: "")
        let body = revokedTokens.contains(token)
            ? "{\"ok\":false,\"error\":\"token_expired\"}"
            : "{\"ok\":true,\"authorization\":\"\(authorization)\"}"
        guard let url = urlRequest.url,
              let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
        else {
            throw TransportError.unexpectedNotHTTPResponse
        }
        return (Data(body.utf8), response)
    }
}

/// A counter that the refresh closure increments.
actor RefreshCounter {
    private(set) var count = 0
    var isBroken = false

    func next() throws -> Int {
        if isBroken {
            throw SimpleMessageError(message: "invalid_grant: the refresh token is revoked")
        }
        count += 1
        return count
    }

    func setBroken(_ isBroken: Bool) {
        self.isBroken = isBroken
    }
}

/// The fake server, the store, the refresh counter and the transport of the demo.
///
/// The view keeps one instance in its state, so that the transport and the buttons talk to the
/// same server and the same store.
@MainActor
final class TransportDemo {
    nonisolated static let tokenLifetime: TimeInterval = 15

    let api = FakeAPITransport()
    let store: InMemoryOAuthCredentialsStore
    let refreshCounter = RefreshCounter()
    let transport: AuthenticatingTransport

    init() {
        let store = InMemoryOAuthCredentialsStore(
            credentials: OAuthCredentials(
                accessToken: "access-0",
                expiresAt: Date().addingTimeInterval(Self.tokenLifetime),
                refreshToken: "refresh-0"
            )
        )
        let refreshCounter = refreshCounter
        self.store = store
        transport = AuthenticatingTransport(
            wrapping: api,
            store: store,
            leeway: 5,
            isTokenExpired: { data, _ in
                String(data: data, encoding: .utf8)?.contains("token_expired") ?? false
            },
            refresh: { _ in
                let count = try await refreshCounter.next()
                return OAuthCredentials(
                    accessToken: "access-\(count)",
                    expiresAt: Date().addingTimeInterval(Self.tokenLifetime),
                    refreshToken: "refresh-\(count)"
                )
            }
        )
    }
}

struct OAuthDemoView: View {
    let readme: LocalizedStringKey = """
    `OAuthAuthorizationSession` opens the authorization page of a provider in a browser and \
    returns the authorization code with the PKCE verifier. `AuthenticatingTransport` adds the \
    bearer token to each request and refreshes it when it expires.
    """

    // MARK: - Authorization session

    @State var authorizationEndpoint = "https://slack.com/oauth/v2/authorize"
    @State var clientID = ""
    @State var scopes = "users:read"
    @State var scopeParameterName = "user_scope"
    @State var redirectURI = "blocksapp://oauth/callback"
    @State var authorizationOutcome = "Not started"

    // MARK: - Authenticating transport

    @State var demo = TransportDemo()

    @State var transportOutcome = "No request sent"
    @State var currentToken = "access-0"
    @State var refreshCount = 0
    @State var isRefreshBroken = false

    var body: some View {
        Form {
            SwiftUI.Section {
                Text(readme)
            }

            SwiftUI.Section("Authorization Session") {
                TextField("Authorization endpoint", text: $authorizationEndpoint)
                TextField("Client ID", text: $clientID)
                TextField("Scopes (space separated)", text: $scopes)
                TextField("Scope parameter name", text: $scopeParameterName)
                TextField("Redirect URI", text: $redirectURI)
                Button("Authorize in Browser") {
                    Task { await authorize() }
                }
                .disabled(clientID.isEmpty)
                Text(authorizationOutcome)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }

            SwiftUI.Section("Authenticating Transport") {
                LabeledContent("Current token", value: currentToken)
                LabeledContent("Refreshes", value: "\(refreshCount)")
                Text("The token expires after \(Int(TransportDemo.tokenLifetime)) seconds. "
                    + "The transport refreshes it 5 seconds before.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Send Request") {
                    Task { await sendRequest() }
                }
                Button("Revoke Current Token on the Server") {
                    Task { await demo.api.revoke(currentToken) }
                }
                Toggle("Break the refresh token", isOn: $isRefreshBroken)
                    .onChange(of: isRefreshBroken) { _, newValue in
                        Task { await demo.refreshCounter.setBroken(newValue) }
                    }
                Text(transportOutcome)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
        }
        #if os(macOS)
        .formStyle(.grouped)
        #endif
        .navigationTitle("OAuth")
    }

    func authorize() async {
        guard let endpoint = URL(string: authorizationEndpoint), let redirect = URL(string: redirectURI) else {
            authorizationOutcome = "The endpoint or the redirect URI is not a valid URL."
            return
        }

        let session = OAuthAuthorizationSession(configuration: .init(
            authorizationEndpoint: endpoint,
            clientID: clientID,
            scopes: scopes.split(separator: " ").map(String.init),
            scopeParameterName: scopeParameterName,
            scopeSeparator: ",",
            redirectURI: redirect
        ))

        do {
            authorizationOutcome = "Waiting for the browser…"
            let result = try await session.authorize()
            authorizationOutcome = "Code: \(result.code)\nVerifier: \(result.codeVerifier)"
        } catch OAuthAuthorizationError.cancelled {
            authorizationOutcome = "Cancelled by the user."
        } catch {
            authorizationOutcome = "Error: \(error.localizedDescription)"
        }
    }

    func sendRequest() async {
        do {
            let request = URLRequest(url: URL(string: "https://api.example.tld/me")!)
            let (data, _) = try await demo.transport.send(urlRequest: request, delegate: nil)
            transportOutcome = "Response: \(String(data: data, encoding: .utf8) ?? "")"
        } catch let error as ReauthenticationRequiredError {
            transportOutcome = "Re-authentication required: \(error.localizedDescription)"
        } catch {
            transportOutcome = "Error: \(error.localizedDescription)"
        }

        refreshCount = await demo.refreshCounter.count
        currentToken = await demo.store.load()?.accessToken ?? "<cleared>"
    }
}

#Preview {
    OAuthDemoView()
}
