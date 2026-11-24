@testable import BlocksCLI
import Foundation
import XCTest

final class FMBenchTests: XCTestCase {
    func testParsesFrontMatterAndBody() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "fm-bench-post", withExtension: "md"))
        let markdown = try String(contentsOf: url, encoding: .utf8)
        let post = BenchCorpus.parse(id: "fm-bench-post", markdown: markdown)

        XCTAssertEqual(post.id, "fm-bench-post")
        XCTAssertEqual(post.title, "How I Decode ISO 8601 Dates from JSON APIs in Swift")
        XCTAssertEqual(
            post.summary,
            "JSONDecoder's .iso8601 strategy rejects fractional seconds, "
                + "and the deferredToDate default isn't what APIs send."
        )
        XCTAssertEqual(post.category, "Journaling")
        XCTAssertEqual(post.tags, ["iOS", "Swift", "JSON"])
        XCTAssertEqual(post.language, "fr")
        XCTAssertTrue(post.body.hasPrefix("This blog post"))
        XCTAssertTrue(post.body.hasSuffix("five words here."))
        XCTAssertEqual(post.wordCount, 16)
    }

    func testMarkdownWithoutFrontMatterIsAllBody() {
        let post = BenchCorpus.parse(id: "plain", markdown: "Just text.")
        XCTAssertNil(post.category)
        XCTAssertEqual(post.tags, [])
        XCTAssertEqual(post.body, "Just text.")
    }

    func testInlineListInFrontMatter() {
        let fields = BenchCorpus.parseFrontMatter(["tags: [\"swift\", yaml]", "draft: false"])
        XCTAssertEqual(fields.lists["tags"], ["swift", "yaml"])
        XCTAssertEqual(fields.scalars["draft"], "false")
    }

    func testJaccardNormalizesTags() {
        XCTAssertEqual(BenchScoring.jaccard(["Swift UI", "iOS"], ["swiftui", "ios"]), 1)
        XCTAssertEqual(BenchScoring.jaccard(["iOS", "Swift"], ["Swift", "Xcode", "macOS"]), 0.25)
        XCTAssertEqual(BenchScoring.jaccard([], []), 1)
        XCTAssertEqual(BenchScoring.jaccard(["iOS"], []), 0)
    }

    func testLocaleHintOnlyForNonEnglish() {
        XCTAssertNil(BenchInstructions.localeHint(language: nil))
        XCTAssertNil(BenchInstructions.localeHint(language: "en"))
        XCTAssertEqual(BenchInstructions.localeHint(language: "fr"), "The person's locale is fr_FR.")
    }

    func testRecordRoundTripsThroughSnakeCaseJSON() throws {
        let record = makeRecord(task: .classify, output: "{\"category\": \"Journaling\"}", truthCategory: "Journaling")
        let data = try BenchRecord.makeEncoder().encode(record)
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertTrue(json.contains("\"run_id\":\"run\""))
        XCTAssertTrue(json.contains("\"item_id\":\"post\""))
        let decoded = try BenchRecord.makeDecoder().decode(BenchRecord.self, from: data)
        XCTAssertEqual(decoded.runId, "run")
        XCTAssertEqual(decoded.truthCategory, "Journaling")
    }

    func testReportScoresClassifyAndTags() {
        let records = [
            makeRecord(task: .classify, output: "{\"category\": \"Journaling\"}", truthCategory: "Journaling"),
            makeRecord(task: .classify, output: "{\"category\": \"Data\"}", truthCategory: "Journaling"),
            makeRecord(task: .classify, output: nil, outcome: .guardrail, truthCategory: "Journaling"),
            makeRecord(task: .tag, output: "{\"tags\": [\"Swift\", \"Xcode\"]}", truthTags: ["Swift", "iOS"]),
            makeRecord(task: .tag, output: "{\"tags\": [\"Maven\"]}", truthTags: ["Java"])
        ]
        let rows = BenchReportRow.build(from: records, byLanguage: false)
        XCTAssertEqual(rows.count, 2)

        let classify = rows[0]
        XCTAssertEqual(classify.task, .classify)
        XCTAssertEqual(classify.calls, 3)
        XCTAssertEqual(classify.outcomes[.success], 2)
        XCTAssertEqual(classify.outcomes[.guardrail], 1)
        XCTAssertEqual(classify.categoryMatch, 0.5)
        XCTAssertEqual(classify.medianLatencyMs, 100)

        let tag = rows[1]
        XCTAssertEqual(tag.tagAnyOverlap, 0.5)
        XCTAssertEqual(try XCTUnwrap(tag.tagJaccard), (1.0 / 3.0 + 0) / 2, accuracy: 0.0001)

        let table = BenchReportFormatter.markdown(rows)
        XCTAssertTrue(table.contains("| classify | A | all | 3 | 2 | 0 | 0 | 1 | 0 | 0 | 100 |"))
        XCTAssertTrue(table.contains("category match 50%"))
    }

    private func makeRecord(
        task: BenchTask,
        output: String?,
        outcome: BenchOutcome = .success,
        truthCategory: String? = nil,
        truthTags: [String]? = nil
    ) -> BenchRecord {
        BenchRecord(
            runId: "run", timestamp: "2026-11-18T00:00:00Z", osVersion: "test", modelVariant: "test", contextSize: 4096,
            itemId: "post", task: task, config: "A", iteration: 0, language: nil,
            instructionsStyle: .role, outputMode: .guided, sampling: .greedy, seed: nil, temperature: nil,
            guardrails: .default, useCase: .general,
            outcome: outcome, output: output, errorDescription: nil, explanation: nil,
            latencyMs: 100, inputTokens: 10, outputTokens: 5,
            truthCategory: truthCategory, truthTags: truthTags, truthSummary: nil
        )
    }
}
