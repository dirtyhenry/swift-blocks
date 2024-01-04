import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

@available(iOS 15.0.0, *)
@available(macOS 12.0, *)
/// A type that can transport URL requests to a server-like target.
public protocol Transport {
    func send(
        urlRequest: URLRequest,
        delegate: URLSessionTaskDelegate?
    ) async throws -> (Data, HTTPURLResponse)
}

#if os(Linux)
// 📜 Last time I checked, async/await data on `URLSession` was not available.
//
// ```sh
// error: value of type 'URLSession' has no member 'data'
// ```
#else
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
#endif
