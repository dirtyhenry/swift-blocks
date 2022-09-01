import Blocks
import XCTest

final class ICalendarTests: XCTestCase {
    func testBasicUsage() throws {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withYear, .withMonth, .withDay, .withTime, .withTimeZone]

        var iCalendarObject = ICalendarObject(productIdentifier: "-//ABC Corporation//NONSGML My Product//")

        let event = ICalendarEventComponent(
            uid: "19970901T130000Z-123401@example.com",
            dateTimeStamp: dateFormatter.date(from: "19970901T130000Z")!,
            dateTimeStart: dateFormatter.date(from: "19970903T163000Z")!,
            dateTimeEnd: dateFormatter.date(from: "19970903T190000Z")!,
            summary: "Annual Employee Review",
            description: "Some more details here."
        )
        iCalendarObject.add(event: event)

        let expectedICAL = """
        BEGIN:VCALENDAR
        VERSION:2.0
        PRODID:-//ABC Corporation//NONSGML My Product//
        BEGIN:VEVENT
        UID:19970901T130000Z-123401@example.com
        DTSTAMP:19970901T130000Z
        DTSTART:19970903T163000Z
        DTEND:19970903T190000Z
        SUMMARY:Annual Employee Review
        DESCRIPTION:Some more details here.
        END:VEVENT
        END:VCALENDAR
        """

        XCTAssertEqual(iCalendarObject.iCalString(formatter: dateFormatter), expectedICAL)
    }
}
