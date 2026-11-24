import Foundation

/// Pure functions that turn records into numbers for the report.
enum BenchScoring {
    /// Lowercases a tag and removes spaces, hyphens and underscores, so `Swift UI` and `swiftui` match.
    static func normalizeTag(_ tag: String) -> String {
        tag.lowercased().filter { !$0.isWhitespace && $0 != "-" && $0 != "_" }
    }

    /// The Jaccard index of two sets of tags, after normalization. Two empty sets give 1.
    static func jaccard(_ lhs: [String], _ rhs: [String]) -> Double {
        let left = Set(lhs.map(normalizeTag))
        let right = Set(rhs.map(normalizeTag))
        let union = left.union(right)
        if union.isEmpty {
            return 1
        }
        return Double(left.intersection(right).count) / Double(union.count)
    }

    static func median(_ values: [Int]) -> Int? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted()
        return sorted[sorted.count / 2]
    }

    static func mean(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    /// The `category` of a guided `classify` output.
    static func category(fromOutput output: String) -> String? {
        decodeObject(output)?["category"] as? String
    }

    /// The `tags` of a guided `tag` output.
    static func tags(fromOutput output: String) -> [String]? {
        decodeObject(output)?["tags"] as? [String]
    }

    /// The `short` summary of a guided `summarize` output, or the text itself for text output.
    static func shortSummary(fromOutput output: String, mode: BenchOutputMode) -> String? {
        switch mode {
        case .guided: decodeObject(output)?["short"] as? String
        case .text: output
        }
    }

    private static func decodeObject(_ json: String) -> [String: Any]? {
        guard let data = json.data(using: .utf8) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }
}

/// One row of the report: one task, one config, and optionally one language.
struct BenchReportRow: Equatable {
    var task: BenchTask
    var config: String
    var language: String?
    var calls = 0
    var outcomes: [BenchOutcome: Int] = [:]
    var medianLatencyMs: Int?
    var meanInputTokens: Double?
    var meanOutputTokens: Double?
    /// `classify`: share of exact matches with the post's category.
    var categoryMatch: Double?
    /// `tag`: mean Jaccard index with the post's tags.
    var tagJaccard: Double?
    /// `tag`: share of calls with at least one tag in common with the post's tags.
    var tagAnyOverlap: Double?
    /// `summarize`: share of short summaries of 160 characters or less.
    var summaryFits: Double?
}

extension BenchReportRow {
    /// Groups `records` by task, config and, when `byLanguage` is set, language, then scores each group.
    static func build(from records: [BenchRecord], byLanguage: Bool) -> [BenchReportRow] {
        struct Key: Hashable {
            let task: BenchTask
            let config: String
            let language: String?
        }
        var groups: [Key: [BenchRecord]] = [:]
        for record in records {
            let language = byLanguage ? (record.language ?? "en") : nil
            groups[Key(task: record.task, config: record.config, language: language), default: []].append(record)
        }
        return groups
            .map { key, group in score(task: key.task, config: key.config, language: key.language, records: group) }
            .sorted { lhs, rhs in
                if lhs.task != rhs.task {
                    return lhs.task.rawValue < rhs.task.rawValue
                }
                if lhs.config != rhs.config {
                    return lhs.config < rhs.config
                }
                return (lhs.language ?? "") < (rhs.language ?? "")
            }
    }

    static func score(task: BenchTask, config: String, language: String?, records: [BenchRecord]) -> BenchReportRow {
        var row = BenchReportRow(task: task, config: config, language: language)
        row.calls = records.count
        for record in records {
            row.outcomes[record.outcome, default: 0] += 1
        }
        row.medianLatencyMs = BenchScoring.median(records.map(\.latencyMs))
        row.meanInputTokens = BenchScoring.mean(records.compactMap { $0.inputTokens.map(Double.init) })
        row.meanOutputTokens = BenchScoring.mean(records.compactMap { $0.outputTokens.map(Double.init) })

        let successes = records.filter { $0.outcome == .success }
        switch task {
        case .classify: row.categoryMatch = categoryMatch(successes)
        case .tag: (row.tagJaccard, row.tagAnyOverlap) = tagAgreement(successes)
        case .summarize: row.summaryFits = summaryFits(successes)
        case .extract, .rewrite: break
        }
        return row
    }

    /// The share of exact matches between the output category and the post category.
    static func categoryMatch(_ records: [BenchRecord]) -> Double? {
        let pairs = records.compactMap { record -> (String, String)? in
            guard let truth = record.truthCategory, let output = record.output,
                  let category = BenchScoring.category(fromOutput: output) else { return nil }
            return (truth, category)
        }
        guard !pairs.isEmpty else { return nil }
        let matches = pairs.filter { $0.0.caseInsensitiveCompare($0.1) == .orderedSame }.count
        return Double(matches) / Double(pairs.count)
    }

    /// The mean Jaccard index, and the share of calls with at least one tag in common.
    static func tagAgreement(_ records: [BenchRecord]) -> (jaccard: Double?, anyOverlap: Double?) {
        let scores = records.compactMap { record -> Double? in
            guard let truth = record.truthTags, !truth.isEmpty, let output = record.output,
                  let tags = BenchScoring.tags(fromOutput: output) else { return nil }
            return BenchScoring.jaccard(truth, tags)
        }
        guard !scores.isEmpty else { return (nil, nil) }
        let overlapping = scores.filter { $0 > 0 }.count
        return (BenchScoring.mean(scores), Double(overlapping) / Double(scores.count))
    }

    /// The share of short summaries of 160 characters or less.
    static func summaryFits(_ records: [BenchRecord]) -> Double? {
        let shorts = records.compactMap { record -> String? in
            guard let output = record.output else { return nil }
            return BenchScoring.shortSummary(fromOutput: output, mode: record.outputMode)
        }
        guard !shorts.isEmpty else { return nil }
        return Double(shorts.filter { $0.count <= 160 }.count) / Double(shorts.count)
    }
}

enum BenchReportFormatter {
    /// Renders rows as a Markdown table.
    static func markdown(_ rows: [BenchReportRow]) -> String {
        var lines: [String] = []
        lines.append(
            "| task | config | lang | calls | ok | soft | refusal | guardrail | ctx | error "
                + "| median ms | in tok | out tok | agreement |"
        )
        lines.append("|---|---|---|---|---|---|---|---|---|---|---|---|---|---|")
        for row in rows {
            func count(_ outcome: BenchOutcome) -> String {
                String(row.outcomes[outcome] ?? 0)
            }
            let agreement: String = switch row.task {
            case .classify: row.categoryMatch.map { "category match \(percent($0))" } ?? "–"
            case .tag:
                [row.tagJaccard.map { "jaccard \(String(format: "%.2f", $0))" },
                 row.tagAnyOverlap.map { "≥1 shared \(percent($0))" }]
                    .compactMap(\.self).joined(separator: ", ")
            case .summarize: row.summaryFits.map { "≤160 chars \(percent($0))" } ?? "–"
            case .extract, .rewrite: "–"
            }
            let errors = (row.outcomes[.error] ?? 0) + (row.outcomes[.unsupportedLanguage] ?? 0)
            let cells: [String] = [
                row.task.rawValue,
                row.config,
                row.language ?? "all",
                String(row.calls),
                count(.success),
                count(.softRefusal),
                count(.refusal),
                count(.guardrail),
                count(.contextSize),
                String(errors),
                row.medianLatencyMs.map(String.init) ?? "–",
                row.meanInputTokens.map { String(format: "%.0f", $0) } ?? "–",
                row.meanOutputTokens.map { String(format: "%.0f", $0) } ?? "–",
                agreement.isEmpty ? "–" : agreement
            ]
            lines.append("| " + cells.joined(separator: " | ") + " |")
        }
        return lines.joined(separator: "\n")
    }

    private static func percent(_ value: Double) -> String {
        String(format: "%.0f%%", value * 100)
    }
}
