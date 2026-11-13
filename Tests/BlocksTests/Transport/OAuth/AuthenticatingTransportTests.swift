@testable import Blocks
import XCTest

#if os(Linux)
// Cannot use this test as `HTTPURLResponse` has no accessible initializers
#else
@available(iOS 15.0.0, *)
@available(macOS 12.0, *)
final class AuthenticatingTransportTests: XCTestCase {
    func testAddsBearerHeaderToRequest() async throws {
        let recorder = RecordingTransport(responses: [.ok()])
        let store = InMemoryOAuthCredentialsStore(
            credentials: OAuthCredentials(accessToken: "access-1", expiresAt: nil, refreshToken: nil)
        )
        let sut = AuthenticatingTransport(
            wrapping: recorder,
            store: store,
            refresh: { _ in XCTFail("No refresh expected"); throw Unreachable() }
        )

        _ = try await sut.send(urlRequest: DummyURLRequest.create(), delegate: nil)

        let requests = await recorder.requests
        XCTAssertEqual(requests.map { $0.value(forHTTPHeaderField: "Authorization") }, ["Bearer access-1"])
    }

    func testRefreshesBeforeSendingWhenAccessTokenIsAboutToExpire() async throws {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let recorder = RecordingTransport(responses: [.ok()])
        let store = InMemoryOAuthCredentialsStore(
            credentials: OAuthCredentials(
                accessToken: "access-1",
                expiresAt: now.addingTimeInterval(30),
                refreshToken: "refresh-1"
            )
        )
        let sut = AuthenticatingTransport(
            wrapping: recorder,
            store: store,
            leeway: 60,
            now: { now },
            refresh: { refreshToken in
                XCTAssertEqual(refreshToken, "refresh-1")
                return OAuthCredentials(
                    accessToken: "access-2",
                    expiresAt: now.addingTimeInterval(3600),
                    refreshToken: "refresh-2"
                )
            }
        )

        _ = try await sut.send(urlRequest: DummyURLRequest.create(), delegate: nil)

        let requests = await recorder.requests
        XCTAssertEqual(requests.map { $0.value(forHTTPHeaderField: "Authorization") }, ["Bearer access-2"])
        let stored = await store.load()
        XCTAssertEqual(stored?.accessToken, "access-2")
        XCTAssertEqual(stored?.refreshToken, "refresh-2")
    }

    func testDoesNotRefreshWhenAccessTokenIsValidBeyondLeeway() async throws {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let recorder = RecordingTransport(responses: [.ok()])
        let store = InMemoryOAuthCredentialsStore(
            credentials: OAuthCredentials(
                accessToken: "access-1",
                expiresAt: now.addingTimeInterval(120),
                refreshToken: "refresh-1"
            )
        )
        let sut = AuthenticatingTransport(
            wrapping: recorder,
            store: store,
            leeway: 60,
            now: { now },
            refresh: { _ in XCTFail("No refresh expected"); throw Unreachable() }
        )

        _ = try await sut.send(urlRequest: DummyURLRequest.create(), delegate: nil)

        let requests = await recorder.requests
        XCTAssertEqual(requests.map { $0.value(forHTTPHeaderField: "Authorization") }, ["Bearer access-1"])
    }

    func testRefreshesOnceAndRetriesOnceWhenResponseSaysTokenIsExpired() async throws {
        let recorder = RecordingTransport(responses: [.unauthorized(), .unauthorized()])
        let store = InMemoryOAuthCredentialsStore(
            credentials: OAuthCredentials(accessToken: "access-1", refreshToken: "refresh-1")
        )
        let refreshCount = Counter()
        let sut = AuthenticatingTransport(
            wrapping: recorder,
            store: store,
            refresh: { _ in
                await refreshCount.increment()
                return OAuthCredentials(accessToken: "access-2", refreshToken: "refresh-2")
            }
        )

        let (_, response) = try await sut.send(urlRequest: DummyURLRequest.create(), delegate: nil)

        XCTAssertEqual(response.statusCode, 401, "The second response is returned as is.")
        let requests = await recorder.requests
        XCTAssertEqual(
            requests.map { $0.value(forHTTPHeaderField: "Authorization") },
            ["Bearer access-1", "Bearer access-2"]
        )
        let count = await refreshCount.value
        XCTAssertEqual(count, 1)
    }

    func testDetectsExpiredTokenInResponseBodyWithCustomDetector() async throws {
        let recorder = RecordingTransport(responses: [
            .ok("{\"ok\":false,\"error\":\"token_expired\"}"),
            .ok("{\"ok\":true}")
        ])
        let store = InMemoryOAuthCredentialsStore(
            credentials: OAuthCredentials(accessToken: "access-1", refreshToken: "refresh-1")
        )
        let sut = AuthenticatingTransport(
            wrapping: recorder,
            store: store,
            isTokenExpired: { data, _ in
                String(data: data, encoding: .utf8)?.contains("token_expired") ?? false
            },
            refresh: { _ in OAuthCredentials(accessToken: "access-2", refreshToken: "refresh-2") }
        )

        let (data, _) = try await sut.send(urlRequest: DummyURLRequest.create(), delegate: nil)

        XCTAssertEqual(String(data: data, encoding: .utf8), "{\"ok\":true}")
        let requests = await recorder.requests
        XCTAssertEqual(
            requests.map { $0.value(forHTTPHeaderField: "Authorization") },
            ["Bearer access-1", "Bearer access-2"]
        )
    }

    func testSharesOneRefreshBetweenConcurrentRequests() async throws {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let requestCount = 5
        let recorder = RecordingTransport(responses: Array(repeating: .ok(), count: requestCount))
        let store = InMemoryOAuthCredentialsStore(
            credentials: OAuthCredentials(accessToken: "access-1", expiresAt: now, refreshToken: "refresh-1")
        )
        let refreshCount = Counter()
        let sut = AuthenticatingTransport(
            wrapping: recorder,
            store: store,
            now: { now },
            refresh: { _ in
                await refreshCount.increment()
                try await Task.sleep(nanoseconds: 50_000_000)
                return OAuthCredentials(
                    accessToken: "access-2",
                    expiresAt: now.addingTimeInterval(3600),
                    refreshToken: "refresh-2"
                )
            }
        )

        try await withThrowingTaskGroup(of: Void.self) { group in
            for _ in 0 ..< requestCount {
                group.addTask {
                    _ = try await sut.send(urlRequest: DummyURLRequest.create(), delegate: nil)
                }
            }
            try await group.waitForAll()
        }

        let count = await refreshCount.value
        XCTAssertEqual(count, 1)
        let requests = await recorder.requests
        XCTAssertEqual(
            requests.map { $0.value(forHTTPHeaderField: "Authorization") },
            Array(repeating: "Bearer access-2", count: requestCount)
        )
    }

    func testSharesOneRefreshWhenConcurrentRequestsGetExpiredTokenResponses() async throws {
        let recorder = RecordingTransport(responses: [.unauthorized(), .unauthorized(), .ok(), .ok()])
        let store = InMemoryOAuthCredentialsStore(
            credentials: OAuthCredentials(accessToken: "access-1", refreshToken: "refresh-1")
        )
        let refreshCount = Counter()
        let sut = AuthenticatingTransport(
            wrapping: recorder,
            store: store,
            refresh: { _ in
                await refreshCount.increment()
                try await Task.sleep(nanoseconds: 50_000_000)
                return OAuthCredentials(accessToken: "access-2", refreshToken: "refresh-2")
            }
        )

        try await withThrowingTaskGroup(of: Void.self) { group in
            for _ in 0 ..< 2 {
                group.addTask {
                    _ = try await sut.send(urlRequest: DummyURLRequest.create(), delegate: nil)
                }
            }
            try await group.waitForAll()
        }

        let count = await refreshCount.value
        XCTAssertEqual(count, 1)
        let requests = await recorder.requests
        XCTAssertEqual(
            requests.map { $0.value(forHTTPHeaderField: "Authorization") },
            ["Bearer access-1", "Bearer access-1", "Bearer access-2", "Bearer access-2"]
        )
    }
}

// MARK: - Test doubles

actor Counter {
    private(set) var value = 0

    func increment() {
        value += 1
    }
}

struct Unreachable: Error {}

@available(iOS 15.0.0, *)
@available(macOS 12.0, *)
actor RecordingTransport: Transport {
    struct Response {
        let data: Data
        let statusCode: Int
        var delayNanoseconds: UInt64 = 0

        static func ok(_ body: String = "{\"ok\":true}") -> Response {
            Response(data: Data(body.utf8), statusCode: 200)
        }

        static func unauthorized(delayNanoseconds: UInt64 = 0) -> Response {
            Response(data: Data(), statusCode: 401, delayNanoseconds: delayNanoseconds)
        }
    }

    private var responses: [Response]
    private(set) var requests: [URLRequest] = []

    init(responses: [Response]) {
        self.responses = responses
    }

    nonisolated func send(
        urlRequest: URLRequest,
        delegate _: (any URLSessionTaskDelegate)?
    ) async throws -> (Data, HTTPURLResponse) {
        try await record(urlRequest)
    }

    private func record(_ urlRequest: URLRequest) async throws -> (Data, HTTPURLResponse) {
        requests.append(urlRequest)
        guard !responses.isEmpty else {
            throw SimpleMessageError(message: "RecordingTransport has no response left.")
        }
        let response = responses.removeFirst()
        if response.delayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: response.delayNanoseconds)
        }
        let httpResponse = HTTPURLResponse(
            url: urlRequest.url!,
            statusCode: response.statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        return (response.data, httpResponse)
    }
}
#endif
