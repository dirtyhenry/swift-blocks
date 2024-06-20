import Foundation

/// A formatter that converts between dates and their ISO 8601 string representations
/// [as JavaScript recommends to do so][1].
///
/// The best way to use this formatter is via `JSONDecoder.javaScriptISO8601()` and `JSONEncoder.javaScriptISO8601()`
/// that this package provides as an extension to `Foundation`.
///
/// With JavaScript, running:
///
/// ```js
/// JSON.stringify({ message: '👋', creationDate: new Date() })
/// ```
///
/// will return
///
/// ```json
/// {
///   "message":"👋",
///   "creationDate":"2022-01-19T21:43:56.683Z"
/// }
/// ```
///
/// No default date formatting strategy can decode these dates using `Foundation` only.
///
/// Instead use:
///
/// ```swift
/// let payload = try JSONDecoder
///     .javaScriptISO8601()
///     .decode(MyCodable.self, from: data)
/// ```
///
/// Or:
///
/// ```swift
/// let data = try JSONEncoder.javaScriptISO8601().encode(payload)
/// ```
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

    /// Returns a date from a decoder holding a single primitive value representing a JavaScript ISO 8601 date.
    ///
    /// This function is intended to be used as a custom implementation of `JSONDecoder.DateDecodingStrategy`.
    ///
    /// ⚠️ This code attempts decoding dates with 2 formatters:
    /// * one that supports fractional seconds
    /// * one that does not.
    /// The reason is that the JSON of the API my app was consuming was coming from a Kotlin backend that used
    /// Java’s `DateTimeFormatter` that stipulates:
    ///
    /// > If the nano-of-second is zero or not available then the format is complete.
    ///
    /// Statistically speaking, 99,9% of the API would be formatted with fractional seconds — that’s why we attempt
    /// decoding dates with this formatter first —, and 0,1% without. 🤷
    ///
    /// - Parameter decoder: The decoder to fetch the data.
    /// - Returns: The date as decoded by a JavaScript ISO 8601 formatter.
    public static func decodedDate(_ decoder: Decoder) throws -> Date {
        let container = try decoder.singleValueContainer()
        let dateAsString = try container.decode(String.self)

        return try date(from: dateAsString) ?? {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Expected date string to be JavaScript-ISO8601-formatted."
            ))
        }()
    }

    /// Encodes a date with as a JavaScript ISO 8601 formatted date with the provided decoder.
    /// - Parameters:
    ///   - date: The date to encode.
    ///   - encoder: The encoder.
    public static func encodeDate(date: Date, encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(fractionalSecondsFormatter.string(from: date))
    }

    public static func date(from dateAsString: String) -> Date? {
        for formatter in [fractionalSecondsFormatter, defaultFormatter] {
            if let res = formatter.date(from: dateAsString) {
                return res
            }
        }

        return nil
    }

    private init() {}
}
