@testable import Blocks
import XCTest

#if os(Linux)
// Cannot use this test as `HTTPURLResponse` has no accessible initializers
#else
@available(iOS 15.0.0, *)
@available(macOS 12.0, *)
final class AuthenticatingTransportReauthenticationTests: XCTestCase {
    func testThrowsReauthenticationRequiredAndClearsStoreWhenRefreshFails() async throws {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let recorder = RecordingTransport(responses: [])
        let store = InMemoryOAuthCredentialsStore(
            credentials: OAuthCredentials(accessToken: "access-1", expiresAt: now, refreshToken: "refresh-1")
        )
        let sut = AuthenticatingTransport(
            wrapping: recorder,
            store: store,
            now: { now },
            refresh: { _ in throw SimpleMessageError(message: "invalid_grant") }
        )

        do {
            _ = try await sut.send(urlRequest: DummyURLRequest.create(), delegate: nil)
            XCTFail("Expected an error")
        } catch let error as ReauthenticationRequiredError {
            guard case let .refreshFailed(underlying) = error.reason else {
                return XCTFail("Unexpected reason: \(error.reason)")
            }
            XCTAssertEqual(underlying.localizedDescription, "invalid_grant")
        }

        let stored = await store.load()
        XCTAssertNil(stored)
        let requests = await recorder.requests
        XCTAssertTrue(requests.isEmpty)
    }

    func testThrowsReauthenticationRequiredWhenStoreIsEmpty() async throws {
        let recorder = RecordingTransport(responses: [])
        let sut = AuthenticatingTransport(
            wrapping: recorder,
            store: InMemoryOAuthCredentialsStore(),
            refresh: { _ in XCTFail("No refresh expected"); throw Unreachable() }
        )

        do {
            _ = try await sut.send(urlRequest: DummyURLRequest.create(), delegate: nil)
            XCTFail("Expected an error")
        } catch let error as ReauthenticationRequiredError {
            guard case .missingCredentials = error.reason else {
                return XCTFail("Unexpected reason: \(error.reason)")
            }
        }
    }

    func testThrowsReauthenticationRequiredWhenExpiredCredentialsHaveNoRefreshToken() async throws {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let recorder = RecordingTransport(responses: [])
        let sut = AuthenticatingTransport(
            wrapping: recorder,
            store: InMemoryOAuthCredentialsStore(
                credentials: OAuthCredentials(accessToken: "access-1", expiresAt: now, refreshToken: nil)
            ),
            now: { now },
            refresh: { _ in XCTFail("No refresh expected"); throw Unreachable() }
        )

        do {
            _ = try await sut.send(urlRequest: DummyURLRequest.create(), delegate: nil)
            XCTFail("Expected an error")
        } catch let error as ReauthenticationRequiredError {
            guard case .missingRefreshToken = error.reason else {
                return XCTFail("Unexpected reason: \(error.reason)")
            }
        }
    }

    func testReauthenticationRequiredErrorDescriptions() {
        XCTAssertEqual(
            ReauthenticationRequiredError(reason: .missingCredentials).localizedDescription,
            "Authentication is required: no credentials are stored."
        )
        XCTAssertEqual(
            ReauthenticationRequiredError(reason: .missingRefreshToken).localizedDescription,
            "Authentication is required: the access token is expired and there is no refresh token."
        )
        XCTAssertEqual(
            ReauthenticationRequiredError(reason: .refreshFailed(SimpleMessageError(message: "boom")))
                .localizedDescription,
            "Authentication is required: the refresh failed (boom)."
        )
    }
}
#endif
