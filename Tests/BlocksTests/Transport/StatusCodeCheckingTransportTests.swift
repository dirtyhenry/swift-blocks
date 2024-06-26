@testable import Blocks
import XCTest

#if os(Linux)
// Cannot use this test as `HTTPURLResponse` has no accessible initializers
#else
@available(iOS 15.0.0, *)
@available(macOS 12.0, *)
final class StatusCodeCheckingTransportTests: XCTestCase {
    func testPassing() async throws {
        let mockTransport = MockTransport()
        let sut = StatusCodeCheckingTransport(wrapping: mockTransport)
        let (data, response) = try await sut.send(urlRequest: DummyURLRequest.create(), delegate: nil)
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(data, mockTransport.data)
    }

    func testThrowing() async throws {
        let expectation = expectation(description: "Transport will throw")
        let mockTransport = MockTransport(response: HTTPURLResponse(
            url: URL(string: "https://github.com/dirtyhenry/swift-blocks")!,
            statusCode: 404,
            httpVersion: nil,
            headerFields: nil
        )!)

        let sut = StatusCodeCheckingTransport(wrapping: mockTransport)

        var caughtStatusCode = 0
        do {
            _ = try await sut.send(urlRequest: DummyURLRequest.create(), delegate: nil)
        } catch let error as WrongStatusCodeError {
            caughtStatusCode = error.statusCode
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 1)

        XCTAssertEqual(caughtStatusCode, 404)
    }

    func testErrorDescription() {
        let sut = WrongStatusCodeError(statusCode: 200, response: nil, responseBody: nil)
        XCTAssertEqual(sut.localizedDescription, "Unexpected HTTP status code: 200")
    }
}
#endif
