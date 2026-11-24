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
public struct PlainDate: Sendable {
    // MARK: - Creating an instance

    /// Creates a plain date from an ISO 8601 string representation.
    ///
    /// - Parameters:
    ///   - dateAsString: The ISO 8601 string representing the date (e.g., `2022-03-02` for March 2nd, 2022).
    ///   - calendar: The calendar to use (default is `.current`).
    /// - Returns: A `PlainDate`, or `nil` if the string is not in the `YYYY-MM-DD` format.
    ///   The initializer also returns `nil` for a day that does not exist, such as `2022-02-30`.
    public init?(from dateAsString: String, calendar: Calendar = .current) {
        guard let date = Self.date(fromISO8601: dateAsString, in: calendar.timeZone) else {
            return nil
        }

        self.init(date: date, calendar: calendar)
    }

    /// Creates a plain date from a `Date` object.
    ///
    /// The initializer keeps the start of the day of `date` in `calendar`. It removes the time of day.
    ///
    /// - Parameters:
    ///   - date: The `Date` to represent.
    ///   - calendar: The calendar to use (default is `.current`).
    public init(date: Date, calendar: Calendar = .current) {
        self.date = calendar.startOfDay(for: date)
        self.calendar = calendar
    }

    // MARK: - Properties

    public let date: Date
    public let calendar: Calendar

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
            fatalError(
                "Runtime issue: please do not use timeStyle in an alternative formatter."
            )
        }
        #endif
        return alternativeFormatter.string(from: date)
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
        Self.iso8601String(for: gregorianDay)
    }
}

extension PlainDate: CustomDebugStringConvertible {
    // MARK: - CustomDebugStringConvertible

    /// A debug description of the `PlainDate` including calendar and time zone details.
    public var debugDescription: String {
        "\(description) (\(calendar) \(calendar.timeZone) \(date))"
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
    ///
    /// - Precondition: The result must be in the range of dates that `calendar` can represent.
    public func advanced(by value: Int) -> PlainDate {
        guard let newDate = calendar.date(byAdding: .day, value: value, to: date) else {
            preconditionFailure("Could not advance \(self) by \(value) days.")
        }

        return PlainDate(date: newDate, calendar: calendar)
    }
}

extension PlainDate: Equatable, Hashable, Comparable {
    // MARK: - Equatable, Hashable and Comparable Conformances

    /// Two plain dates are equal when they have the same ISO 8601 day, also with different calendars.
    public static func == (lhs: PlainDate, rhs: PlainDate) -> Bool {
        lhs.gregorianDay == rhs.gregorianDay
    }

    public func hash(into hasher: inout Hasher) {
        let (year, month, day) = gregorianDay
        hasher.combine(year)
        hasher.combine(month)
        hasher.combine(day)
    }

    public static func < (lhs: PlainDate, rhs: PlainDate) -> Bool {
        lhs.gregorianDay < rhs.gregorianDay
    }
}

extension PlainDate {
    private static let gregorianCalendar = Calendar(identifier: .gregorian)

    /// The year, month and day of this plain date in the Gregorian calendar, in the time zone of its calendar.
    private var gregorianDay: (year: Int, month: Int, day: Int) {
        var gregorian = Self.gregorianCalendar
        gregorian.timeZone = calendar.timeZone
        let components = gregorian.dateComponents([.year, .month, .day], from: date)
        return (components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }
}

public extension PlainDate {
    // MARK: - Weekday and Components

    /// Represents a day of the week.
    enum Weekday: Int, Sendable {
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
        guard let weekday = components.weekday, let result = Weekday(rawValue: weekday) else {
            preconditionFailure("No weekday found for \(self)")
        }

        return result
    }

    /// The year and week number of this `PlainDate`.
    var yearWeek: String {
        Self.iso8601YearWeek(for: date, in: calendar.timeZone)
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

// MARK: - ISO 8601 strings

/// `PlainDate` reads and writes ISO 8601 strings with `Calendar`, not with `ISO8601DateFormatter`:
///
/// - `ISO8601DateFormatter` is lenient. It accepts `2022-3-2`, `20220302` and `+2022-03-02`, and it rolls over
///   days that do not exist: `2022-02-30` becomes `2022-03-02`.
/// - `ISO8601DateFormatter` is expensive to make. One formatter costs about 200 µs. The code made one for each
///   call, which made `description`, decoding and encoding about 150 times slower than the `Calendar` path.
///
/// Keep this extension as the only place that knows the `YYYY-MM-DD` and `YYYY-Www` formats.
private extension PlainDate {
    static let iso8601Calendar = Calendar(identifier: .iso8601)

    /// Returns the start of the day in `timeZone` for a `YYYY-MM-DD` string, or `nil` if the string is not
    /// in that format or names a day that does not exist.
    static func date(fromISO8601 string: String, in timeZone: TimeZone) -> Date? {
        let parts = string.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3,
              parts[0].count == 4, parts[1].count == 2, parts[2].count == 2,
              parts.allSatisfy({ $0.allSatisfy { $0.isASCII && $0.isNumber } }),
              let year = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2])
        else {
            return nil
        }

        var gregorian = gregorianCalendar
        gregorian.timeZone = timeZone
        let components = DateComponents(year: year, month: month, day: day)

        // The calendar rolls over days that do not exist: 2022-02-30 becomes 2022-03-02.
        guard components.isValidDate(in: gregorian) else {
            return nil
        }

        return gregorian.date(from: components)
    }

    /// Returns the `YYYY-MM-DD` string for a Gregorian day.
    static func iso8601String(for day: (year: Int, month: Int, day: Int)) -> String {
        String(format: "%04d-%02d-%02d", day.year, day.month, day.day)
    }

    /// Returns the `YYYY-Www` string for a date, with the ISO 8601 week rules.
    static func iso8601YearWeek(for date: Date, in timeZone: TimeZone) -> String {
        var iso8601 = iso8601Calendar
        iso8601.timeZone = timeZone
        let components = iso8601.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return String(format: "%04d-W%02d", components.yearForWeekOfYear ?? 0, components.weekOfYear ?? 0)
    }
}

// MARK: - Codable Conformance

extension PlainDate: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        guard let instance = PlainDate(from: value) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Could not turn \(value) into a PlainDate."
            )
        }

        self = instance
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
    /// Creates a custom URL for the current PlainDate instance, using the "day" URL scheme.
    ///
    /// The host portion of the URL is the date in ISO 8601 format, but with hyphens replaced by periods
    /// (for example, 2025-06-02 becomes 2025.06.02). This is intended for integration with third-party
    /// apps (such as Craft) that recognize or handle this style of date-based linking.
    func craftURL() -> URL {
        var components = URLComponents()
        components.scheme = "day"
        components.host = description.replacingOccurrences(of: "-", with: ".")

        // The host has only digits and periods, thus `URLComponents` always makes a URL.
        guard let url = components.url else {
            preconditionFailure("Could not generate Craft URL for date \(self).")
        }

        return url
    }
}
