@testable import Blocks
import XCTest

final class PlainDateTests: XCTestCase {
    func testBasicUsage() throws {
        let randomDate: PlainDate = "2022-01-19"
        XCTAssertEqual(randomDate.description, "2022-01-19")
        XCTAssertEqual(randomDate.advanced(by: 1).description, "2022-01-20")
        XCTAssertEqual(randomDate.advanced(by: 12).description, "2022-01-31")
        XCTAssertEqual(randomDate.advanced(by: 13).description, "2022-02-01")
    }

    func testDaylightSavingTimePeriods() throws {
        // In France, time will change on March 27th in 2022.
        let march26 = PlainDate(from: "2022-03-26", calendar: .parisCalendar())!
        XCTAssertEqual(march26.description, "2022-03-26")
        XCTAssertEqual(march26.advanced(by: 1).description, "2022-03-27")
        XCTAssertEqual(march26.advanced(by: 2).description, "2022-03-28")

        // In New York, time will change on March 13th in 2022.
        let march12 = PlainDate(from: "2022-03-12", calendar: .newYorkCalendar())!
        XCTAssertEqual(march12.description, "2022-03-12")
        XCTAssertEqual(march12.advanced(by: 1).description, "2022-03-13")
        XCTAssertEqual(march12.advanced(by: 2).description, "2022-03-14")
    }

    func testFormattingRangeOfDates() throws {
        let march1st = PlainDate(from: "2022-03-01", calendar: .parisCalendar())!
        let aWeekLater = march1st.advanced(by: 7)
        let range = march1st ..< aWeekLater

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.timeZone = Calendar.parisCalendar().timeZone
        let array = Array(range).map { $0.string(with: formatter) }
        XCTAssertEqual(array, ["20220301", "20220302", "20220303", "20220304", "20220305", "20220306", "20220307"])
    }

    func testDistanceOfDatesIsConsistent() throws {
        let januaryFirst = PlainDate(from: "2022-01-01", calendar: .parisCalendar())!

        measure {
            for offset in 1 ... 10000 {
                XCTAssertEqual(januaryFirst.advanced(by: offset).distance(to: januaryFirst), -offset)
            }
        }
    }

    struct MockCodable: Codable {
        let dateString: PlainDate
    }

    let mockJSON = """
    {"dateString":"2022-01-19"}
    """

    func testEncodable() throws {
        let mockCodable = MockCodable(dateString: "2022-01-19")
        let json = try JSONEncoder().encode(mockCodable)
        let jsonString = String(data: json, encoding: .utf8)
        XCTAssertEqual(jsonString, mockJSON)
    }

    func testDecodable() throws {
        let mockCodable = try JSONDecoder().decode(MockCodable.self, from: mockJSON.data(using: .utf8)!)
        XCTAssertEqual("2022-01-19", mockCodable.dateString.description)
    }

    func testWeekdays() {
        XCTAssertEqual(PlainDate(stringLiteral: "2023-03-13").weekday, PlainDate.Weekday.monday)
        XCTAssertEqual(PlainDate(stringLiteral: "2023-03-14").weekday, PlainDate.Weekday.tuesday)
        XCTAssertEqual(PlainDate(stringLiteral: "2023-03-15").weekday, PlainDate.Weekday.wednesday)
        XCTAssertEqual(PlainDate(stringLiteral: "2023-03-16").weekday, PlainDate.Weekday.thursday)
        XCTAssertEqual(PlainDate(stringLiteral: "2023-03-17").weekday, PlainDate.Weekday.friday)
        XCTAssertEqual(PlainDate(stringLiteral: "2023-03-18").weekday, PlainDate.Weekday.saturday)
        XCTAssertEqual(PlainDate(stringLiteral: "2023-03-19").weekday, PlainDate.Weekday.sunday)
    }

    func testAdvancedToWeekday() {
        XCTAssertEqual(PlainDate(stringLiteral: "2023-03-13").advanced(toNext: .tuesday).description, "2023-03-14")
        XCTAssertEqual(PlainDate(stringLiteral: "2023-03-14").advanced(toNext: .tuesday).description, "2023-03-14")
        XCTAssertEqual(PlainDate(stringLiteral: "2023-03-15").advanced(toNext: .tuesday).description, "2023-03-21")
        XCTAssertEqual(PlainDate(stringLiteral: "2023-03-16").advanced(toNext: .tuesday).description, "2023-03-21")
        XCTAssertEqual(PlainDate(stringLiteral: "2023-03-17").advanced(toNext: .tuesday).description, "2023-03-21")
        XCTAssertEqual(PlainDate(stringLiteral: "2023-03-18").advanced(toNext: .tuesday).description, "2023-03-21")
        XCTAssertEqual(PlainDate(stringLiteral: "2023-03-19").advanced(toNext: .tuesday).description, "2023-03-21")
    }

    func testYearWeek() {
        XCTAssertEqual(PlainDate(stringLiteral: "2023-03-12").yearWeek, "2023-W10")
        XCTAssertEqual(PlainDate(stringLiteral: "2023-03-13").yearWeek, "2023-W11")
        XCTAssertEqual(PlainDate(stringLiteral: "2023-03-14").yearWeek, "2023-W11")
        XCTAssertEqual(PlainDate(stringLiteral: "2023-03-15").yearWeek, "2023-W11")
        XCTAssertEqual(PlainDate(stringLiteral: "2023-03-16").yearWeek, "2023-W11")
        XCTAssertEqual(PlainDate(stringLiteral: "2023-03-17").yearWeek, "2023-W11")
        XCTAssertEqual(PlainDate(stringLiteral: "2023-03-18").yearWeek, "2023-W11")
        XCTAssertEqual(PlainDate(stringLiteral: "2023-03-19").yearWeek, "2023-W11")
        XCTAssertEqual(PlainDate(stringLiteral: "2023-03-20").yearWeek, "2023-W12")
    }
}
