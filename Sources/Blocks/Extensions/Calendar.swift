import Foundation

public extension Calendar {
    // MARK: - Specific calendars

    /// An instance of a gregorian calendar set with the Paris timezone.
    /// - Returns: the calendar used in Paris, France.
    static func parisCalendar() -> Calendar {
        create(calendarIdentifier: .gregorian, timeZoneIdentifier: "Europe/Paris")
    }

    /// An instance of a gregorian calendar set with the New York timezone.
    /// - Returns: the calendar used in New York, USA.
    static func newYorkCalendar() -> Calendar {
        create(calendarIdentifier: .gregorian, timeZoneIdentifier: "America/New_York")
    }

    internal static func create(calendarIdentifier: Calendar.Identifier, timeZoneIdentifier: String) -> Calendar {
        guard let timeZone = TimeZone(identifier: timeZoneIdentifier) else {
            fatalError("Unknown time zone identifier: \(timeZoneIdentifier)")
        }

        var result = Calendar(identifier: calendarIdentifier)
        result.timeZone = timeZone
        return result
    }
}
