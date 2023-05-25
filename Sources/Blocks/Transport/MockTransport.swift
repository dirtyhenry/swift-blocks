import Foundation

@available(iOS 15.0.0, *)
@available(macOS 12.0, *)
final class MockTransport: Transport {
    let data: Data
    let response: HTTPURLResponse

    init(data: Data, response: HTTPURLResponse) {
        self.data = data
        self.response = response
    }

    func send(urlRequest _: URLRequest, delegate _: URLSessionTaskDelegate?) async throws -> (Data, HTTPURLResponse) {
        (data, response)
    }
}
