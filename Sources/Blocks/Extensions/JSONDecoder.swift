import Foundation

@available(macOS 10.13, *)
public extension JSONDecoder.DateDecodingStrategy {
    static func javaScriptISO8601() -> JSONDecoder.DateDecodingStrategy {
        .custom(JavaScriptISO8601DateFormatter.decodedDate)
    }
}

@available(macOS 10.13, *)
public extension JSONDecoder {
    static func javaScriptISO8601() -> JSONDecoder {
        let res = JSONDecoder()
        res.dateDecodingStrategy = .javaScriptISO8601()
        return res
    }
}

public extension JSONDecoder {
    func decode<T>(
        _: T.Type,
        fromResource resource: String,
        withExtension fileExtension: String = "json",
        in bundle: Bundle
    ) throws -> T where T: Decodable {
        guard let bundledResourceURL = bundle.url(forResource: resource, withExtension: fileExtension) else {
            throw BlocksError.couldNotLocateFile("\(resource).\(fileExtension)")
        }

        let data = try Data(contentsOf: bundledResourceURL)
        return try decode(T.self, from: data)
    }
}
