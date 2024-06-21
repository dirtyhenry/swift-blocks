#if canImport(os)
@testable import Blocks
import XCTest

@available(iOS 15.0.0, *)
@available(macOS 12.0, *)
final class LoggingTransportTests: XCTestCase {
    func testPassing() async throws {
        let mockData = Data("Hello LoggingTransport".utf8)
        let mockTransport = MockTransport(data: mockData)
        let sut = LoggingTransport(wrapping: mockTransport, subsystem: "net.mickf.swift-blocks", category: "UnitTests")
        let (data, response) = try await sut.send(urlRequest: DummyURLRequest.create(), delegate: nil)
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(data, mockData)
    }
}
#endif
