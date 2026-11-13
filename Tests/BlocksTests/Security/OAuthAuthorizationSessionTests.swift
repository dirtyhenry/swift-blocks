#if canImport(CryptoKit)
@testable import Blocks
#if canImport(AuthenticationServices)
import AuthenticationServices
#endif
import XCTest

final class OAuthAuthorizationSessionTests: XCTestCase {
    let configuration = OAuthAuthorizationSession.Configuration(
        authorizationEndpoint: URL(string: "https://provider.tld/oauth/authorize")!,
        clientID: "client-123",
        scopes: ["chat:write", "users:read"],
        redirectURI: URL(string: "myapp://oauth/callback")!
    )

    let seeds = PKCE.ClientSeeds(codeVerifier: "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk")

    func testAuthorizationURLContainsPKCEAndStateParameters() throws {
        let request = try OAuthAuthorizationSession.makeRequest(
            configuration: configuration,
            seeds: seeds,
            state: "state-abc"
        )

        let components = try XCTUnwrap(URLComponents(url: request.url, resolvingAgainstBaseURL: false))
        XCTAssertEqual(components.scheme, "https")
        XCTAssertEqual(components.host, "provider.tld")
        XCTAssertEqual(components.path, "/oauth/authorize")
        XCTAssertEqual(components.queryValue("response_type"), "code")
        XCTAssertEqual(components.queryValue("client_id"), "client-123")
        XCTAssertEqual(components.queryValue("redirect_uri"), "myapp://oauth/callback")
        XCTAssertEqual(components.queryValue("scope"), "chat:write users:read")
        XCTAssertEqual(components.queryValue("state"), "state-abc")
        XCTAssertEqual(components.queryValue("code_challenge"), "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM")
        XCTAssertEqual(components.queryValue("code_challenge_method"), "S256")
        XCTAssertEqual(request.state, "state-abc")
        XCTAssertEqual(request.codeVerifier, "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk")
    }

    func testAuthorizationURLUsesCustomScopeParameterAndSeparator() throws {
        var configuration = configuration
        configuration.scopeParameterName = "user_scope"
        configuration.scopeSeparator = ","
        configuration.additionalQueryItems = [URLQueryItem(name: "team", value: "T123")]

        let request = try OAuthAuthorizationSession.makeRequest(
            configuration: configuration,
            seeds: seeds,
            state: "state-abc"
        )

        let components = try XCTUnwrap(URLComponents(url: request.url, resolvingAgainstBaseURL: false))
        XCTAssertEqual(components.queryValue("user_scope"), "chat:write,users:read")
        XCTAssertNil(components.queryValue("scope"))
        XCTAssertEqual(components.queryValue("team"), "T123")
    }

    func testAuthorizationURLKeepsExistingQueryItemsOfTheEndpoint() throws {
        var configuration = configuration
        configuration.authorizationEndpoint = try XCTUnwrap(
            URL(string: "https://provider.tld/oauth/authorize?tenant=acme")
        )

        let request = try OAuthAuthorizationSession.makeRequest(
            configuration: configuration,
            seeds: seeds,
            state: "state-abc"
        )

        let components = try XCTUnwrap(URLComponents(url: request.url, resolvingAgainstBaseURL: false))
        XCTAssertEqual(components.queryValue("tenant"), "acme")
        XCTAssertEqual(components.queryValue("client_id"), "client-123")
    }

    func testCallbackWithMatchingStateReturnsCodeAndVerifier() throws {
        let result = try OAuthAuthorizationSession.parseCallback(
            url: XCTUnwrap(URL(string: "myapp://oauth/callback?code=auth-code-1&state=state-abc")),
            expectedState: "state-abc",
            codeVerifier: "verifier-1"
        )

        XCTAssertEqual(result, OAuthAuthorizationSession.Result(code: "auth-code-1", codeVerifier: "verifier-1"))
    }

    func testCallbackWithWrongStateIsRejected() throws {
        XCTAssertThrowsError(try OAuthAuthorizationSession.parseCallback(
            url: XCTUnwrap(URL(string: "myapp://oauth/callback?code=auth-code-1&state=other")),
            expectedState: "state-abc",
            codeVerifier: "verifier-1"
        )) { error in
            guard case OAuthAuthorizationError.stateMismatch = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testCallbackWithMissingStateIsRejected() throws {
        XCTAssertThrowsError(try OAuthAuthorizationSession.parseCallback(
            url: XCTUnwrap(URL(string: "myapp://oauth/callback?code=auth-code-1")),
            expectedState: "state-abc",
            codeVerifier: "verifier-1"
        )) { error in
            guard case OAuthAuthorizationError.stateMismatch = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testCallbackErrorParametersBecomeProviderError() throws {
        XCTAssertThrowsError(try OAuthAuthorizationSession.parseCallback(
            url: XCTUnwrap(URL(
                string: "myapp://oauth/callback?error=access_denied&error_description=User%20said%20no&state=state-abc"
            )),
            expectedState: "state-abc",
            codeVerifier: "verifier-1"
        )) { error in
            guard case let OAuthAuthorizationError.providerError(code, description) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(code, "access_denied")
            XCTAssertEqual(description, "User said no")
        }
    }

    func testCallbackWithoutCodeIsRejected() throws {
        XCTAssertThrowsError(try OAuthAuthorizationSession.parseCallback(
            url: XCTUnwrap(URL(string: "myapp://oauth/callback?state=state-abc")),
            expectedState: "state-abc",
            codeVerifier: "verifier-1"
        )) { error in
            guard case OAuthAuthorizationError.missingCode = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testErrorDescriptions() {
        XCTAssertEqual(OAuthAuthorizationError.cancelled.localizedDescription, "The user cancelled the authorization.")
        XCTAssertEqual(
            OAuthAuthorizationError.stateMismatch.localizedDescription,
            "The authorization callback has a wrong state."
        )
        XCTAssertEqual(
            OAuthAuthorizationError.providerError(code: "access_denied", description: nil).localizedDescription,
            "The provider refused the authorization: access_denied."
        )
        XCTAssertEqual(
            OAuthAuthorizationError.providerError(code: "access_denied", description: "User said no")
                .localizedDescription,
            "The provider refused the authorization: access_denied. User said no"
        )
    }

    #if canImport(AuthenticationServices) && (os(iOS) || os(macOS))
    func testUserCancellationIsADistinctError() {
        let sessionError = ASWebAuthenticationSessionError(.canceledLogin)
        guard case OAuthAuthorizationError.cancelled = OAuthAuthorizationSession.mapSessionError(sessionError) else {
            return XCTFail("Expected a cancelled error")
        }
    }

    func testOtherSessionErrorsAreWrapped() {
        let sessionError = ASWebAuthenticationSessionError(.presentationContextNotProvided)
        guard case let OAuthAuthorizationError.sessionFailed(underlying) = OAuthAuthorizationSession
            .mapSessionError(sessionError)
        else {
            return XCTFail("Expected a sessionFailed error")
        }
        XCTAssertEqual((underlying as? ASWebAuthenticationSessionError)?.code, .presentationContextNotProvided)
    }
    #endif
}

private extension URLComponents {
    func queryValue(_ name: String) -> String? {
        queryItems?.first { $0.name == name }?.value
    }
}
#endif
