@testable import Blocks
import XCTest

@available(iOS 15.0.0, *)
@available(macOS 12.0, *)
final class StatusCodeCheckingTransportTests: XCTestCase {
    func testPassing() async throws {
        let mockTransport = MockTransport(data: "Hello".data(using: .utf8)!, response: HTTPURLResponse(
            url: URL(string: "https://github.com/dirtyhenry/blocks")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil)!)

        let dummyURLRequest = try DummyURLRequest().create()
        let sut = StatusCodeCheckingTransport(wrapping: mockTransport)
        let (data, response) = try await sut.send(urlRequest: dummyURLRequest, delegate: nil)
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(data, "Hello".data(using: .utf8)!)
    }

    func testThrowing() async throws {
        let expectation = expectation(description: "Transport will throw")
        let mockTransport = MockTransport(data: "Hello".data(using: .utf8)!, response: HTTPURLResponse(
            url: URL(string: "https://github.com/dirtyhenry/blocks")!,
            statusCode: 404,
            httpVersion: nil,
            headerFields: nil)!)

        let dummyURLRequest = try DummyURLRequest().create()
        let sut = StatusCodeCheckingTransport(wrapping: mockTransport)

        var caughtStatusCode = 0
        do {
            _ = try await sut.send(urlRequest: dummyURLRequest, delegate: nil)
        } catch let TransportError.unexpectedHTTPStatusCode(statusCode) {
            caughtStatusCode = statusCode
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 1)

        XCTAssertEqual(caughtStatusCode, 404)
    }
}
