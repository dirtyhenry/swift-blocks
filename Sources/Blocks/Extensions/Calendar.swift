import Foundation

extension Calendar {
    static func frenchCalendar() -> Calendar {
        create(calendarIdentifier: .gregorian, timeZoneIdentifier: "Europe/Paris")
    }

    static func newYorkCalendar() -> Calendar {
        create(calendarIdentifier: .gregorian, timeZoneIdentifier: "America/New_York")
    }

    static func create(calendarIdentifier: Calendar.Identifier, timeZoneIdentifier: String) -> Calendar {
        guard let timeZone = TimeZone(identifier: timeZoneIdentifier) else {
            fatalError("Unknown time zone identifier: \(timeZoneIdentifier)")
        }

        var result = Calendar(identifier: calendarIdentifier)
        result.timeZone = timeZone
        return result
    }
}
