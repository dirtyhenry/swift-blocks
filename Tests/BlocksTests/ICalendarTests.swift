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
        BEGIN:VCALENDAR\r
        VERSION:2.0\r
        PRODID:-//ABC Corporation//NONSGML My Product//\r
        BEGIN:VEVENT\r
        UID:19970901T130000Z-123401@example.com\r
        DTSTAMP:19970901T130000Z\r
        DTSTART:19970903T163000Z\r
        DTEND:19970903T190000Z\r
        SUMMARY:Annual Employee Review\r
        DESCRIPTION:Some more details here.\r
        END:VEVENT\r
        END:VCALENDAR
        """

        XCTAssertEqual(iCalendarObject.iCalString(formatter: dateFormatter), expectedICAL)
    }
}
