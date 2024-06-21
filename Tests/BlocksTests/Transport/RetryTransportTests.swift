@testable import Blocks
import XCTest

#if os(Linux)
// Cannot use this test as `HTTPURLResponse` has no accessible initializers
#else
@available(iOS 15.0.0, *)
@available(macOS 12.0, *)
final class RetryTransportTests: XCTestCase {
    func testPassing() async throws {
        let mockData = Data("Hello MockTransport".utf8)
        let mockTransport = MockTransport(data: mockData)
        let sut = RetryTransport(wrapping: mockTransport)
        let (data, response) = try await sut.send(urlRequest: DummyURLRequest.create(), delegate: nil)
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(data, mockData)
    }

    func testThrowing() async throws {
        let expectation = expectation(description: "Transport will throw")
        let mockTransport = ThrowingTransport()
        let sut = RetryTransport(wrapping: mockTransport)

        var nbErrors = 0
        do {
            _ = try await sut.send(urlRequest: DummyURLRequest.create(), delegate: nil)
        } catch let error as RetryTransportError {
            nbErrors = error.transportErrors.count
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 1)
        XCTAssertEqual(nbErrors, 3)
    }

    func testRecovering() async throws {
        let recoveringTransport = RecoveringTransport()
        let sut = RetryTransport(wrapping: recoveringTransport)
        let (data, response) = try await sut.send(urlRequest: DummyURLRequest.create(), delegate: nil)
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(data, recoveringTransport.mockTransport.data)
        XCTAssertEqual(recoveringTransport.nbOfCalls, 3)
    }

    func testRecoveringWithShortDelay() async throws {
        let mockTransport = RecoveringTransport()
        let sut = RetryTransport(wrapping: mockTransport, delay: { _ in
            try! await Task.sleep(nanoseconds: 200_000_000) // 200ms
        })

        let before = Date()
        let (data, response) = try await sut.send(urlRequest: DummyURLRequest.create(), delegate: nil)
        let after = Date()
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(data, mockTransport.mockTransport.data)
        XCTAssertEqual(mockTransport.nbOfCalls, 3)
        let duration = after.timeIntervalSinceReferenceDate - before.timeIntervalSinceReferenceDate
        XCTAssert(duration > 0.4)
        if isRunningOnDeveloperMachine() {
            XCTAssertEqual(duration, 0.4, accuracy: 0.05, "Duration of \(duration) should be close to 400ms.")
        }
    }

    func testErrorDescription() {
        let sut = RetryTransportError(transportErrors: [])
        XCTAssertEqual(
            sut.localizedDescription,
            "Sending the request threw more errors than RetryTransport could retry: 0"
        )
    }
}

struct ThrowingTransport: Transport {
    func send(
        urlRequest _: URLRequest,
        delegate _: (any URLSessionTaskDelegate)?
    ) async throws -> (Data, HTTPURLResponse) {
        throw SimpleMessageError(message: "ThrowingTransport just throws.")
    }
}

@available(iOS 15.0.0, *)
@available(macOS 12.0, *)
class RecoveringTransport: Transport {
    let mockTransport: MockTransport
    let throwingTransport: ThrowingTransport
    let maxNumberOfCalls: Int

    var nbOfCalls = 0

    init(
        mockTransport: MockTransport = .init(),
        throwingTransport: ThrowingTransport = .init(),
        maxNumberOfCalls: Int = 3
    ) {
        self.mockTransport = mockTransport
        self.throwingTransport = throwingTransport
        self.maxNumberOfCalls = maxNumberOfCalls
    }

    func send(urlRequest: URLRequest, delegate: (any URLSessionTaskDelegate)?) async throws -> (Data, HTTPURLResponse) {
        nbOfCalls = nbOfCalls + 1
        if nbOfCalls < maxNumberOfCalls {
            return try await throwingTransport.send(urlRequest: urlRequest, delegate: delegate)
        } else {
            return try await mockTransport.send(urlRequest: urlRequest, delegate: delegate)
        }
    }
}
#endif
