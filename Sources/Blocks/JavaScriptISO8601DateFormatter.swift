import Foundation

/// A formatter that converts between dates and their ISO 8601 string representations
/// [as JavaScript recommends to do so][1].
///
/// [1]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Date/toJSON
@available(macOS 10.13, *)
public class JavaScriptISO8601DateFormatter {
    static let fractionalSecondsFormatter: ISO8601DateFormatter = {
        let res = ISO8601DateFormatter()
        // The default format options is .withInternetDateTime.
        // We need to add .withFractionalSeconds to parse dates with milliseconds.
        res.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return res
    }()

    static let defaultFormatter = ISO8601DateFormatter()

    static func decodedDate(_ decoder: Decoder) throws -> Date {
        let container = try decoder.singleValueContainer()
        let dateAsString = try container.decode(String.self)

        // ⚠️ In this code, I attempt decoding dates with 2 formatters: one that supports fractional seconds and one
        // that does not. The reason is that the JSON of the API my app was consuming was coming from a Kotlin backend
        // that used Java’s `DateTimeFormatter` that stipulates:
        //
        // > If the nano-of-second is zero or not available then the format is complete.
        //
        // Statistically speaking, 99,9% of the API would be formatted with fractional seconds — that’s why we attempt
        // decoding dates with this formatter first —, and 0,1% without. 🤷
        for formatter in [fractionalSecondsFormatter, defaultFormatter] {
            if let res = formatter.date(from: dateAsString) {
                return res
            }
        }

        throw DecodingError.dataCorrupted(DecodingError.Context(
            codingPath: decoder.codingPath,
            debugDescription: "Expected date string to be JavaScript-ISO8601-formatted."
        ))
    }

    static func encodeDate(date: Date, encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(fractionalSecondsFormatter.string(from: date))
    }

    private init() {}
}
