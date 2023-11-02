import Foundation

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
    @available(iOS 15.0.0, *)
    @available(macOS 12.0, *)
    public final class MockTransport: Transport {
        let data: Data
        let response: HTTPURLResponse

        public init(data: Data, response: HTTPURLResponse) {
            self.data = data
            self.response = response
        }

        public func send(urlRequest _: URLRequest, delegate _: URLSessionTaskDelegate?) async throws -> (Data, HTTPURLResponse) {
            (data, response)
        }
    }
#endif
