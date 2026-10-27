import Blocks
import Foundation
import XCTest

final class FrontMatterEncoderTests: XCTestCase {
    private let encoder = FrontMatterEncoder()

    // MARK: - Scalars

    func testEncodesScalarsInDeclarationOrder() throws {
        struct Note: Encodable {
            let title: String
            let draft: Bool
            let rating: Int
        }

        let output = try encoder.encode(Note(title: "Hello", draft: false, rating: 4))

        XCTAssertEqual(output, """
        ---
        title: "Hello"
        draft: false
        rating: 4
        ---

        """)
    }

    func testStringsAreJSONEncoded() throws {
        struct Note: Encodable {
            let title: String
        }

        let output = try encoder.encode(Note(title: "Say \"hi\": #1\n- not a list 🎉"))

        XCTAssertEqual(output, """
        ---
        title: "Say \\"hi\\": #1\\n- not a list 🎉"
        ---

        """)
    }

    func testPlainDateIsWrittenAsISODate() throws {
        struct Note: Encodable {
            let date: PlainDate
        }

        let output = try encoder.encode(Note(date: PlainDate(stringLiteral: "2026-10-27")))

        XCTAssertEqual(output, "---\ndate: 2026-10-27\n---\n")
    }

    func testURLIsWrittenAsString() throws {
        struct Note: Encodable {
            let source: URL
        }

        let output = try encoder.encode(Note(source: XCTUnwrap(URL(string: "https://example.com/a?b=c&d=e#f"))))

        XCTAssertEqual(output, "---\nsource: \"https://example.com/a?b=c&d=e#f\"\n---\n")
    }

    func testArrayOfScalarsIsWrittenAsFlowSequence() throws {
        struct Note: Encodable {
            let tags: [String]
            let scores: [Int]
            let aliases: [String]
        }

        let output = try encoder.encode(Note(tags: ["swift", "a, b"], scores: [1, 2], aliases: []))

        XCTAssertEqual(output, """
        ---
        tags: ["swift", "a, b"]
        scores: [1, 2]
        aliases: []
        ---

        """)
    }

    func testNilOptionalsAreLeftOut() throws {
        struct Note: Encodable {
            let title: String
            let rating: Int?
            let draft: Bool?
        }

        let output = try encoder.encode(Note(title: "A", rating: nil, draft: true))

        XCTAssertEqual(output, "---\ntitle: \"A\"\ndraft: true\n---\n")
    }

    func testRawRepresentableEnumIsWrittenAsItsRawValue() throws {
        enum Status: String, Encodable {
            case published
        }

        struct Note: Encodable {
            let status: Status
        }

        XCTAssertEqual(try encoder.encode(Note(status: .published)), "---\nstatus: \"published\"\n---\n")
    }

    // MARK: - Rejected values

    func testNestedObjectIsRejected() {
        struct Author: Encodable {
            let name: String
        }

        struct Note: Encodable {
            let title: String
            let author: Author
        }

        XCTAssertThrowsError(try encoder.encode(Note(title: "A", author: Author(name: "B")))) { error in
            XCTAssertEqual(error as? FrontMatterEncodingError, .unsupportedValue(key: "author"))
            XCTAssertTrue(error.localizedDescription.contains("\"author\""))
        }
    }

    func testNestedArrayIsRejected() {
        struct Note: Encodable {
            let matrix: [[Int]]
        }

        XCTAssertThrowsError(try encoder.encode(Note(matrix: [[1]]))) { error in
            XCTAssertEqual(error as? FrontMatterEncodingError, .unsupportedValue(key: "matrix"))
        }
    }

    func testFloatingPointNumberIsRejected() {
        struct Note: Encodable {
            let rating: Double
        }

        XCTAssertThrowsError(try encoder.encode(Note(rating: 4.5))) { error in
            XCTAssertEqual(error as? FrontMatterEncodingError, .unsupportedValue(key: "rating"))
        }
    }

    func testDictionaryAndDateAreRejected() {
        struct WithDictionary: Encodable {
            let links: [String: String]
        }

        struct WithDate: Encodable {
            let updated: Date
        }

        XCTAssertThrowsError(try encoder.encode(WithDictionary(links: ["a": "b"]))) { error in
            XCTAssertEqual(error as? FrontMatterEncodingError, .unsupportedValue(key: "links"))
        }
        XCTAssertThrowsError(try encoder.encode(WithDate(updated: Date()))) { error in
            XCTAssertEqual(error as? FrontMatterEncodingError, .unsupportedValue(key: "updated"))
        }
    }

    func testDuplicateKeyIsRejected() {
        XCTAssertThrowsError(try encoder.encode(DuplicateTitle())) { error in
            XCTAssertEqual(error as? FrontMatterEncodingError, .duplicateKey("title"))
        }
    }

    func testValueWithoutKeysIsRejected() {
        XCTAssertThrowsError(try encoder.encode(["a", "b"])) { error in
            XCTAssertEqual(error as? FrontMatterEncodingError, .notKeyed)
        }
    }

    // MARK: - YAML compatibility

    #if os(macOS) || os(Linux)
    func testTrickyTitlesRoundTripThroughYAMLParser() throws {
        struct Note: Encodable {
            let title: String
            let tags: [String]
        }

        let titles = [
            "Say \"hi\"",
            "Key: value",
            "# Not a comment",
            "- not a list",
            "Line one\nLine two",
            "Party 🎉",
            "yes",
            "2026-10-27",
            "'single' quotes \\ backslash",
            "Delete \u{7F} next \u{85} line \u{9F}"
        ]

        for title in titles {
            let frontMatter = try encoder.encode(Note(title: title, tags: [title]))
            let parsed = try parseYAML(frontMatter)
            XCTAssertEqual(parsed["title"] as? String, title, frontMatter)
            XCTAssertEqual(parsed["tags"] as? [String], [title], frontMatter)
        }
    }

    func testKeysThatYAMLReadsAsOtherTypesStayStrings() throws {
        struct Settings: Encodable {
            let yes: Bool
            let off: Int
            let null: String
        }

        let frontMatter = try encoder.encode(Settings(yes: true, off: 1, null: "x"))
        let parsed = try parseYAML(frontMatter)

        XCTAssertEqual(parsed["yes"] as? Bool, true, frontMatter)
        XCTAssertEqual(parsed["off"] as? Int, 1, frontMatter)
        XCTAssertEqual(parsed["null"] as? String, "x", frontMatter)
    }

    /// Parses the YAML between the `---` lines with Ruby's YAML parser and returns it as a dictionary.
    private func parseYAML(_ frontMatter: String) throws -> [String: Any] {
        let script = "require 'yaml'; require 'json'; require 'date'; "
            + "print JSON.generate(YAML.safe_load(STDIN.read.split(/^---$/)[1], permitted_classes: [Date]))"
        let output: ProcessOutput
        do {
            output = try ProcessRunner().run(
                URL(fileURLWithPath: "/usr/bin/env"),
                arguments: ["ruby", "-e", script],
                input: Data(frontMatter.utf8)
            )
        } catch ProcessRunnerError.nonZeroExit(127, _) {
            throw XCTSkip("Ruby is not installed.")
        }
        let object = try JSONSerialization.jsonObject(with: Data(output.stdout.utf8))
        return try XCTUnwrap(object as? [String: Any])
    }
    #endif
}

/// Writes the `title` key two times.
private struct DuplicateTitle: Encodable {
    enum CodingKeys: String, CodingKey {
        case title
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("A", forKey: .title)
        try container.encode("B", forKey: .title)
    }
}
