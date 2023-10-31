import Foundation

@available(macOS 10.13, *)
public extension JSONEncoder.DateEncodingStrategy {
    static func javaScriptISO8601() -> JSONEncoder.DateEncodingStrategy {
        .custom(JavaScriptISO8601DateFormatter.encodeDate)
    }
}

@available(macOS 10.13, *)
public extension JSONEncoder {
    static func javaScriptISO8601() -> JSONEncoder {
        let res = JSONEncoder()
        res.dateEncodingStrategy = .javaScriptISO8601()
        return res
    }

    static func prettyEncoder() -> JSONEncoder {
        let result = JSONEncoder.javaScriptISO8601()
        result.outputFormatting = [.prettyPrinted, .sortedKeys]
        return result
    }
}
