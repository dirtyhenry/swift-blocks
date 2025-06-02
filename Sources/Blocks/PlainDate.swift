import Foundation

/// A string that represents dates without time, using their ISO 8601 representations.
///
/// `PlainDate` provides a way to handle dates with no time — such as `2022-03-02` for March 2nd of 2022 — to
/// perform operations with convenience, including adding days, dealing with ranges, and more.
///
/// ## Usage Overview
///
/// A plain date can be created from a string literal, or directly using a `Date` object. It supports date range
/// iteration, addition of days, and custom formatting.
///
/// ```swift
/// let march1st: PlainDate = "2022-03-01"
/// let aWeekLater = march1st.advanced(by: 7)
/// for day in march1st ..< aWeekLater {
///   print(day)
/// }
/// ```
public struct PlainDate {
    // MARK: - Creating an instance

    /// Creates a plain date from an ISO 8601 string representation.
    ///
    /// - Parameters:
    ///   - dateAsString: The ISO 8601 string representing the date (e.g., `2022-03-02` for March 2nd, 2022).
    ///   - calendar: The calendar to use (default is `.current`).
    /// - Returns: A `PlainDate`, or `nil` if the string could not be parsed into a valid date.
    public init?(from dateAsString: String, calendar: Calendar = .current) {
        let formatter = Self.createFormatter(timeZone: calendar.timeZone)
        guard let date = formatter.date(from: dateAsString) else {
            return nil
        }

        self.init(date: date, calendar: calendar, formatter: formatter)
    }

    /// Creates a plain date from a `Date` object.
    ///
    /// - Parameters:
    ///   - date: The `Date` to represent.
    ///   - calendar: The calendar to use (default is `.current`).
    public init(date: Date, calendar: Calendar = .current) {
        self.init(date: date, calendar: calendar, formatter: Self.createFormatter(timeZone: calendar.timeZone))
    }

    private init(date: Date, calendar: Calendar = .current, formatter: ISO8601DateFormatter) {
        self.formatter = formatter
        self.date = date
        self.calendar = calendar
    }

    // MARK: - Properties

    private let formatter: ISO8601DateFormatter
    let date: Date
    let calendar: Calendar

    // MARK: - Converting to other formats

    /// Returns a string representation of the date using a custom formatter.
    ///
    /// - Note: Avoid using an `alternativeFormatter` with a `timeStyle` other than `.none`.
    ///
    /// - Parameter alternativeFormatter: The formatter to use.
    /// - Returns: A string representing the date.
    public func string(with alternativeFormatter: DateFormatter) -> String {
        #if DEBUG
        if alternativeFormatter.timeStyle != .none {
            fatalError("Runtime issue: please do not use timeStyle in an alternative formatter.")
        }
        #endif
        return alternativeFormatter.string(from: date)
    }

    private static func createFormatter(timeZone: TimeZone) -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        formatter.timeZone = timeZone
        return formatter
    }
}

extension PlainDate: ExpressibleByStringLiteral {
    // MARK: - ExpressibleByStringLiteral

    /// Allows `PlainDate` to be initialized from a string literal.
    ///
    /// Example:
    /// ```swift
    /// let date: PlainDate = "2022-03-02"
    /// ```
    public init(stringLiteral value: String) {
        guard let instance = PlainDate(from: value) else {
            fatalError("Could not turn \(value) into a DateString.")
        }

        self = instance
    }
}

extension PlainDate: CustomStringConvertible {
    // MARK: - CustomStringConvertible

    /// A string description of the `PlainDate` in ISO 8601 format.
    public var description: String {
        formatter.string(from: date)
    }
}

extension PlainDate: CustomDebugStringConvertible {
    // MARK: - CustomDebugStringConvertible

    /// A debug description of the `PlainDate` including calendar and time zone details.
    public var debugDescription: String {
        "\(formatter.string(from: date)) (\(calendar) \(calendar.timeZone) \(date))"
    }
}

extension PlainDate: Strideable {
    // MARK: - Strideable Conformance

    /// Calculates the distance in days to another `PlainDate`.
    public func distance(to other: PlainDate) -> Int {
        if #available(macOS 10.15, iOS 13.0, *) {
            // 🐇 A faster working — so far — alternative.
            let timeInterval = date.distance(to: other.date)
            return Int(round(timeInterval / 86400.0))
        } else {
            // 🐢 Intellectually satisfying but a little slow.
            let start = calendar.ordinality(of: .day, in: .era, for: date)
            let end = calendar.ordinality(of: .day, in: .era, for: other.date)

            guard let start, let end else {
                fatalError("The distance between 2 dates could not be computed.")
            }

            return end - start
        }
    }

    /// Advances the date by a specified number of days.
    public func advanced(by value: Int) -> PlainDate {
        let newDate = calendar.date(byAdding: .day, value: value, to: date)!
        return PlainDate(date: newDate, calendar: calendar, formatter: formatter)
    }
}

extension PlainDate: Equatable, Hashable, Comparable {}

public extension PlainDate {
    // MARK: - Weekday and Components

    /// Represents a day of the week.
    enum Weekday: Int {
        case sunday = 1
        case monday = 2
        case tuesday = 3
        case wednesday = 4
        case thursday = 5
        case friday = 6
        case saturday = 7
    }

    /// The day of the week for this `PlainDate`.
    var weekday: Weekday {
        let components = calendar.dateComponents([.weekday], from: date)
        guard let result = Weekday(rawValue: components.weekday!) else {
            fatalError("No weekday found for \(self)")
        }

        return result
    }

    /// The year and week number of this `PlainDate`.
    var yearWeek: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withYear, .withWeekOfYear, .withDashSeparatorInDate]
        formatter.timeZone = calendar.timeZone
        return formatter.string(from: date)
    }

    /// Advances the date to the next specified weekday.
    func advanced(toNext outputWeekday: Weekday) -> PlainDate {
        var advancingDay = self
        while advancingDay.weekday != outputWeekday {
            advancingDay = advancingDay.advanced(by: 1)
        }
        return advancingDay
    }
}

public extension PlainDate {
    /// The date components (year, month, day) of this `PlainDate`.
    var dateComponents: DateComponents {
        calendar.dateComponents([.year, .month, .day], from: date)
    }
}

// MARK: - Codable Conformance

extension PlainDate: Decodable {
    public init(from decoder: Decoder) throws {
        try self.init(stringLiteral: decoder.singleValueContainer().decode(String.self))
    }
}

extension PlainDate: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

@available(*, deprecated, renamed: "PlainDate", message: "Cf. Temporal effort in JS.")
public typealias DateString = PlainDate

// MARK: - 3rd-Party Apps helpers

public extension PlainDate {
    func craftURL() throws -> URL {
        var components = URLComponents()
        components.scheme = "day"
        components.host = description.replacingOccurrences(of: "-", with: ".")

        guard let url = components.url else {
            throw SimpleMessageError(message: "Could not generate Craft URL for date \(self).")
        }

        return url
    }
}
