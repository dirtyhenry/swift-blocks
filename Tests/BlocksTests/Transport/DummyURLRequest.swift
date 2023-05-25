@testable import Blocks
import Foundation

struct DummyURLRequest {
    func create() throws -> URLRequest {
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
