import Foundation

/// A string that represents dates using their ISO 8601 representations.
///
/// `DateString` is a way to handle dates with no time — such as `2022-03-02` for March 2nd of 2022 — to
/// perform operations with convenience including adding days, dealing with ranges, etc.
///
/// ## Usage Overview
///
/// A date string can be initiated from a string literal, and can be used to create ranges.
///
/// ```swift
/// let dateString: DateString = "2022-03-01"
/// let aWeekLater = dateString.advanced(by: 7)
/// for day in march1st ..< aWeekLater {
///   print(day)
/// }
/// ```
public struct DateString {
    // MARK: - Creating an instance

    /// Returns a date string initialized using their ISO 8601 representation.
    /// - Parameters:
    ///   - dateAsString: The ISO 8601 representation of the date. For instance, `2022-03-02`for March 2nd of 2022.
    ///   - calendar: The calendar — including the time zone — to use. The default is the current calendar.
    /// - Returns:A date string, or `nil` if a valid date could not be created from `dateAsString`.
    public init?(from dateAsString: String, calendar: Calendar = .current) {
        let formatter = Self.createFormatter(timeZone: calendar.timeZone)
        guard let date = formatter.date(from: dateAsString) else {
            return nil
        }

        self.init(date: date, calendar: calendar, formatter: formatter)
    }

    private init(date: Date, calendar: Calendar = .current, formatter: ISO8601DateFormatter? = nil) {
        self.formatter = formatter ?? Self.createFormatter(timeZone: calendar.timeZone)
        self.date = date
        self.calendar = calendar
    }

    // MARK: - Properties

    private let formatter: ISO8601DateFormatter
    private let date: Date
    private let calendar: Calendar

    // MARK: - Converting to other formats

    /// Returns a string representation of the date that the system formats using the receiver’s current settings.
    ///
    /// Use this method only if you need a string representation of the date that is not ISO 8601.
    ///
    /// The return value might be irrelevant if the date formatter uses some time information.
    ///
    /// - Parameter alternativeFormatter: The date formatter to use.
    /// - Returns: A string representation of the date.
    public func string(with alternativeFormatter: DateFormatter) -> String {
        alternativeFormatter.string(from: date)
    }

    private static func createFormatter(timeZone: TimeZone) -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        formatter.timeZone = timeZone
        return formatter
    }
}

extension DateString: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(from: value)!
    }
}

extension DateString: CustomStringConvertible {
    public var description: String {
        formatter.string(from: date)
    }
}

extension DateString: CustomDebugStringConvertible {
    public var debugDescription: String {
        "\(formatter.string(from: date)) (\(calendar) \(calendar.timeZone) \(date))"
    }
}

@available(macOS 10.15, *)
extension DateString: Strideable {
    public func distance(to other: DateString) -> Int {
        let timeInterval = date.distance(to: other.date)
        return Int(round(timeInterval / 86400.0))
    }

    public func advanced(by value: Int) -> DateString {
        let newDate = calendar.date(byAdding: .day, value: value, to: date)!
        return DateString(date: newDate, calendar: calendar, formatter: formatter)
    }
}
