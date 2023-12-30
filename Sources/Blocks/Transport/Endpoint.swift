import Foundation
#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

/// Built-in Content Types
public enum ContentType: String {
    case json = "application/json"
    case xml = "application/xml"
    case urlencoded = "application/x-www-form-urlencoded"
}

/// This describes an endpoint returning `A` values. It contains both a `URLRequest` and a way to parse the response.
///
/// This is an adaptation of https://github.com/objcio/tiny-networking/ that makes use of `Transport` instead of `URLSession`
/// to improve testability and composition.
///
/// Also, JSON defaults encoder and decoder are using the ones from this package.
public struct Endpoint<A> {
    /// The HTTP Method
    public enum Method: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case patch = "PATCH"
        case delete = "DELETE"
    }

    /// The request for this endpoint
    public var request: URLRequest

    /// This is used to (try to) parse a response into an `A`.
    var parse: (Data?, URLResponse?) -> Result<A, Error>

    /// Transforms the result
    public func map<B>(_ f: @escaping (A) -> B) -> Endpoint<B> {
        Endpoint<B>(request: request, parse: { value, response in
            parse(value, response).map(f)
        })
    }

    /// Transforms the result
    public func compactMap<B>(_ transform: @escaping (A) -> Result<B, Error>) -> Endpoint<B> {
        Endpoint<B>(request: request, parse: { data, response in
            parse(data, response).flatMap(transform)
        })
    }

    /// Create a new Endpoint.
    ///
    /// - Parameters:
    ///   - method: the HTTP method
    ///   - url: the endpoint's URL
    ///   - accept: the content type for the `Accept` header
    ///   - contentType: the content type for the `Content-Type` header
    ///   - body: the body of the request.
    ///   - headers: additional headers for the request
    ///   - query: query parameters to append to the url
    ///   - parse: this converts a response into an `A`.
    public init(
        _ method: Method,
        url: URL,
        accept: ContentType? = nil,
        contentType: ContentType? = nil,
        body: Data? = nil,
        headers: [URLRequestHeaderItem] = [],
        query: [URLQueryItem] = [],
        parse: @escaping (Data?, URLResponse?) -> Result<A, Error>
    ) {
        var requestUrl: URL
        if query.isEmpty {
            requestUrl = url
        } else {
            var comps = URLComponents(url: url, resolvingAgainstBaseURL: true)!
            comps.queryItems = comps.queryItems ?? []
            comps.queryItems!.append(contentsOf: query)
            requestUrl = comps.url!
        }
        request = URLRequest(url: requestUrl)
        if let a = accept {
            request.setValue(a.rawValue, forHTTPHeaderField: "Accept")
        }
        if let ct = contentType {
            request.setValue(ct.rawValue, forHTTPHeaderField: "Content-Type")
        }
        for header in headers {
            request.setHTTPHeaderField(header)
        }
        request.httpMethod = method.rawValue

        // body *needs* to be the last property that we set, because of this bug: https://bugs.swift.org/browse/SR-6687
        request.httpBody = body

        self.parse = parse
    }

    /// Creates a new Endpoint from a request
    ///
    /// - Parameters:
    ///   - request: the URL request
    ///   - expectedStatusCode: the status code that's expected. If this returns false for a given status code, parsing fails.
    ///   - parse: this converts a response into an `A`.
    public init(request: URLRequest, parse: @escaping (Data?, URLResponse?) -> Result<A, Error>) {
        self.request = request
        self.parse = parse
    }
}

// MARK: - CustomStringConvertible

extension Endpoint: CustomStringConvertible {
    public var description: String {
        let data = request.httpBody ?? Data()

        let components: [String] = [
            request.httpMethod ?? "GET",
            request.url?.absoluteString ?? "<no url>",
            String(data: data, encoding: .utf8)
        ]
        .compactMap { $0 }
        .filter { !$0.isEmpty }

        return components.joined(separator: " ")
    }
}

// MARK: - where A == ()

public extension Endpoint where A == () {
    /// Creates a new endpoint without a parse function.
    ///
    /// - Parameters:
    ///   - method: the HTTP method
    ///   - url: the endpoint's URL
    ///   - accept: the content type for the `Accept` header
    ///   - contentType: the content type for the `Content-Type` header
    ///   - body: the body of the request.
    ///   - headers: additional headers for the request
    ///   - query: query parameters to append to the url
    init(_ method: Method, url: URL, accept: ContentType? = nil, contentType: ContentType? = nil, body: Data? = nil, headers: [URLRequestHeaderItem] = [], query: [URLQueryItem] = []) {
        self.init(method, url: url, accept: accept, contentType: contentType, body: body, headers: headers, query: query, parse: { _, _ in .success(()) })
    }

    /// Creates a new endpoint without a parse function.
    ///
    /// - Parameters:
    ///   - method: the HTTP method
    ///   - json: the HTTP method
    ///   - url: the endpoint's URL
    ///   - accept: the content type for the `Accept` header
    ///   - body: the body of the request. This gets encoded using a default `JSONEncoder` instance.
    ///   - headers: additional headers for the request
    ///   - expectedStatusCode: the status code that's expected. If this returns false for a given status code, parsing fails.
    ///   - query: query parameters to append to the url
    ///   - encoder: the encoder that's used for encoding `A`s.
    init(
        json method: Method,
        url: URL,
        accept: ContentType? = .json,
        body: some Encodable,
        headers: [URLRequestHeaderItem] = [],
        query: [URLQueryItem] = [],
        encoder: JSONEncoder = JSONEncoder.javaScriptISO8601()
    ) {
        let b = try! encoder.encode(body)
        self.init(method, url: url, accept: accept, contentType: .json, body: b, headers: headers, query: query, parse: { _, _ in .success(()) })
    }
}

// MARK: - where A: Decodable

public extension Endpoint where A: Decodable {
    /// Creates a new endpoint.
    ///
    /// - Parameters:
    ///   - method: the HTTP method
    ///   - url: the endpoint's URL
    ///   - accept: the content type for the `Accept` header
    ///   - headers: additional headers for the request
    ///   - query: query parameters to append to the url
    ///   - decoder: the decoder that's used for decoding `A`s.
    init(
        json method: Method,
        url: URL,
        accept: ContentType = .json,
        headers: [URLRequestHeaderItem] = [],
        query: [URLQueryItem] = [],
        decoder: JSONDecoder = JSONDecoder.javaScriptISO8601()
    ) {
        self.init(method, url: url, accept: accept, body: nil, headers: headers, query: query) { data, _ in
            Result {
                guard let dat = data else { throw NoDataError() }
                return try decoder.decode(A.self, from: dat)
            }
        }
    }

    /// Creates a new endpoint.
    ///
    /// - Parameters:
    ///   - method: the HTTP method
    ///   - url: the endpoint's URL
    ///   - accept: the content type for the `Accept` header
    ///   - body: the body of the request. This is encoded using a default encoder.
    ///   - headers: additional headers for the request
    ///   - query: query parameters to append to the url
    ///   - decoder: the decoder that's used for decoding `A`s.
    ///   - encoder: the encoder that's used for encoding `A`s.
    init(
        json method: Method,
        url: URL,
        accept: ContentType = .json,
        body: (some Encodable)? = nil,
        headers: [URLRequestHeaderItem] = [],
        query: [URLQueryItem] = [],
        decoder: JSONDecoder = JSONDecoder.javaScriptISO8601(),
        encoder: JSONEncoder = JSONEncoder.javaScriptISO8601()
    ) {
        let b = body.map { try! encoder.encode($0) }
        self.init(method, url: url, accept: accept, contentType: .json, body: b, headers: headers, query: query) { data, _ in
            Result {
                guard let dat = data else { throw NoDataError() }
                return try decoder.decode(A.self, from: dat)
            }
        }
    }
}

/// Signals that a response's data was unexpectedly nil.
public struct NoDataError: Error {
    public init() {}
}

/// An unknown error
public struct UnknownError: Error {
    public init() {}
}

@available(iOS 15.0.0, *)
@available(macOS 12.0, *)
public extension Transport {
    @discardableResult
    /// Loads an endpoint by creating (and directly resuming) a data task.
    ///
    /// - Parameters:
    ///   - e: The endpoint.
    ///   - onComplete: The completion handler.
    /// - Returns: The data task.
    func load<A>(_ endpoint: Endpoint<A>) async throws -> A {
        let (data, httpResponse) = try await send(urlRequest: endpoint.request, delegate: nil)
        let result = endpoint.parse(data, httpResponse)
        return try result.get()
    }
}
