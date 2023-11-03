@testable import Blocks
import XCTest

@available(iOS 15.0.0, *)
@available(macOS 12.0, *)
final class LoggingTransportTests: XCTestCase {
    func testPassing() async throws {
        let mockTransport = MockTransport(data: "Hello".data(using: .utf8)!, response: HTTPURLResponse(
            url: URL(string: "https://github.com/dirtyhenry/swift-blocks")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil)!)

        let dummyURLRequest = try DummyURLRequest().create()
        let sut = LoggingTransport(wrapping: mockTransport, subsystem: "net.mickf.swift-blocks", category: "UnitTests")
        let (data, response) = try await sut.send(urlRequest: dummyURLRequest, delegate: nil)
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(data, "Hello".data(using: .utf8)!)
    }
}
