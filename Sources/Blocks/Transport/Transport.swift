import Foundation

@available(iOS 15.0.0, *)
@available(macOS 12.0, *)
/// A type that can transport URL requests to a server-like target.
public protocol Transport {
    func send(
        urlRequest: URLRequest,
        delegate: URLSessionTaskDelegate?
    ) async throws -> (Data, HTTPURLResponse)
}

@available(iOS 15.0.0, *)
@available(macOS 12.0, *)
extension URLSession: Transport {
    public func send(
        urlRequest: URLRequest,
        delegate: URLSessionTaskDelegate?
    ) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await self.data(for: urlRequest, delegate: delegate)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TransportError.unexpectedNotHTTPResponse
        }

        return (data, httpResponse)
    }
}

public enum TransportError: Error {
    case unexpectedNotHTTPResponse
    case unmetURLComponentsRequirements
}
