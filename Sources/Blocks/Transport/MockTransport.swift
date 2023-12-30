import Foundation

@available(iOS 15.0.0, *)
@available(macOS 12.0, *)
public final class MockTransport: Transport {
    let data: Data
    let response: HTTPURLResponse?

    public init(data: Data, response: HTTPURLResponse? = nil) {
        self.data = data
        self.response = response
    }

    public func send(
        urlRequest: URLRequest,
        delegate _: URLSessionTaskDelegate?
    ) async throws -> (Data, HTTPURLResponse) {
        let actualResponse: HTTPURLResponse

        if let response {
            actualResponse = response
        } else {
            guard let fallbackURL = URL(string: "https://foo.tld/bar"),
                  let httpResponse = HTTPURLResponse(
                      url: urlRequest.url ?? fallbackURL,
                      statusCode: 200,
                      httpVersion: nil,
                      headerFields: nil
                  )
            else {
                throw SimpleMessageError(message: "`MockTransport` implementaion looks buggy, please review it.")
            }

            actualResponse = httpResponse
        }

        return (data, actualResponse)
    }
}
