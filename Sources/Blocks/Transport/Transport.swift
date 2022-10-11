import Foundation

@available(macOS 12.0, *)
public protocol Transport {
    func send(urlRequest: URLRequest, delegate: URLSessionTaskDelegate?) async throws -> (Data, HTTPURLResponse)
}

@available(macOS 12.0, *)
extension URLSession: Transport {
    public func send(urlRequest: URLRequest, delegate: URLSessionTaskDelegate?) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await self.data(for: urlRequest, delegate: delegate)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TransportError.unexpectedNotHTTPResponse
        }

        return (data, httpResponse)
    }
}

enum TransportError: Error {
    case unexpectedNotHTTPResponse
    case unmetURLComponentsRequirements
}
