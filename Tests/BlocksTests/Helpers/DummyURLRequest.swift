@testable import Blocks
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

enum DummyURLRequest {
    static func create() throws -> URLRequest {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "foo.tld"
        urlComponents.path = "/bar"

        guard let url = urlComponents.url else {
            throw TransportError.unmetURLComponentsRequirements
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        return request
    }
}
