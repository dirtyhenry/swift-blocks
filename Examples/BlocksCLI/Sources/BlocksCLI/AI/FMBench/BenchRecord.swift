import ArgumentParser
import Foundation

/// A task the benchmark runs on each item.
enum BenchTask: String, CaseIterable, Codable, Sendable, ExpressibleByArgument {
    /// Pick one category from the categories found in the corpus.
    case classify
    /// Return up to five tags.
    case tag
    /// Write a 160-character summary and three bullets.
    case summarize
    /// List languages, frameworks, tools and years named in the text.
    case extract
    /// Rewrite a short piece of product copy. Runs on built-in samples, not on the corpus.
    case rewrite

    /// Tasks that read the corpus of posts.
    static let corpusTasks: [BenchTask] = [.classify, .tag, .summarize, .extract]
}

/// How a call ended.
enum BenchOutcome: String, Codable, Sendable {
    /// The model returned content.
    case success = "ok"
    /// The model returned text that starts like a refusal. Only possible with text output.
    case softRefusal
    /// The model threw a `refusal` error. Only possible with guided generation.
    case refusal
    /// A guardrail blocked the input or the output.
    case guardrail
    /// The input did not fit the context window.
    case contextSize
    /// The language or locale is not supported.
    case unsupportedLanguage
    /// Any other error. See `errorDescription`.
    case error
}

/// How the instructions are written.
enum BenchInstructionsStyle: String, Codable, Sendable {
    /// A role, the domain, and the task, in two to four sentences.
    case role
    /// One imperative sentence.
    case minimal
}

/// How the model returns its answer.
enum BenchOutputMode: String, Codable, Sendable {
    /// Guided generation: a `@Generable` type or a dynamic schema.
    case guided
    /// A plain `String`.
    case text
}

enum BenchSampling: String, Codable, Sendable {
    case greedy
    /// `random(top: 40, seed:)`.
    case randomTop40
}

enum BenchGuardrails: String, Codable, Sendable {
    case `default`
    case permissive
}

enum BenchUseCase: String, Codable, Sendable {
    case general
    case contentTagging
}

/// A named combination of settings. The keys match the research note.
struct BenchConfig: Sendable, Identifiable {
    var id: String {
        key
    }

    let key: String
    let tasks: Set<BenchTask>
    let instructions: BenchInstructionsStyle
    let output: BenchOutputMode
    let sampling: BenchSampling
    let temperature: Double?
    let guardrails: BenchGuardrails
    let useCase: BenchUseCase
    let purpose: String

    static let all: [BenchConfig] = [
        BenchConfig(
            key: "A", tasks: Set(BenchTask.allCases), instructions: .role, output: .guided,
            sampling: .greedy, temperature: nil, guardrails: .default, useCase: .general,
            purpose: "Baseline: guided generation, role instructions, greedy sampling."
        ),
        BenchConfig(
            key: "B", tasks: [.classify, .tag, .summarize], instructions: .role, output: .guided,
            sampling: .randomTop40, temperature: 0.7, guardrails: .default, useCase: .general,
            purpose: "Seeded random sampling: how much the answer moves."
        ),
        BenchConfig(
            key: "C", tasks: [.classify, .tag, .summarize], instructions: .minimal, output: .guided,
            sampling: .greedy, temperature: nil, guardrails: .default, useCase: .general,
            purpose: "One-line instructions: what the role line buys."
        ),
        BenchConfig(
            key: "D", tasks: [.summarize, .rewrite], instructions: .role, output: .text,
            sampling: .greedy, temperature: nil, guardrails: .default, useCase: .general,
            purpose: "Text output: what structure costs."
        ),
        BenchConfig(
            key: "E", tasks: [.rewrite], instructions: .role, output: .text,
            sampling: .greedy, temperature: nil, guardrails: .permissive, useCase: .general,
            purpose: "Permissive guardrails on text output: guardrail versus model refusal."
        ),
        BenchConfig(
            key: "F", tasks: [.tag], instructions: .role, output: .guided,
            sampling: .greedy, temperature: nil, guardrails: .default, useCase: .contentTagging,
            purpose: "The content tagging use case against the general model."
        )
    ]

    static func named(_ key: String) -> BenchConfig? {
        all.first { $0.key.caseInsensitiveCompare(key) == .orderedSame }
    }
}

/// One line of the JSON Lines output.
struct BenchRecord: Codable, Sendable {
    var runId: String
    var timestamp: String
    var osVersion: String
    var modelVariant: String
    var contextSize: Int?

    var itemId: String
    var task: BenchTask
    var config: String
    var iteration: Int
    var language: String?

    var instructionsStyle: BenchInstructionsStyle
    var outputMode: BenchOutputMode
    var sampling: BenchSampling
    var seed: UInt64?
    var temperature: Double?
    var guardrails: BenchGuardrails
    var useCase: BenchUseCase

    var outcome: BenchOutcome
    /// JSON for guided output, plain text otherwise.
    var output: String?
    var errorDescription: String?
    /// The model's own explanation of a refusal. Model-generated, not an error message.
    var explanation: String?

    var latencyMs: Int
    var inputTokens: Int?
    var outputTokens: Int?

    var truthCategory: String?
    var truthTags: [String]?
    var truthSummary: String?

    static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return encoder
    }

    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}

/// A short piece of product copy for the `rewrite` task.
struct BenchRewriteSample: Sendable {
    let id: String
    let text: String

    /// Six samples. The last two reuse the words that caused refusals in May 2026.
    static let all: [BenchRewriteSample] = [
        BenchRewriteSample(
            id: "r01-todo",
            text: "Our app is very fast and good and lets you do all your tasks super easily!!!"
        ),
        BenchRewriteSample(
            id: "r02-bakery",
            text: "We bake bread every morning with the finest ingredients, come taste the difference."
        ),
        BenchRewriteSample(
            id: "r03-bike",
            text: "Bring your bike in and our guys will fix it up in no time."
        ),
        BenchRewriteSample(
            id: "r04-newsletter",
            text: "Subscribe to our newsletter and never miss out on anything ever again."
        ),
        BenchRewriteSample(
            id: "r05-complain",
            text: "Before you complain, check our FAQ: most issues are solved there."
        ),
        BenchRewriteSample(
            id: "r06-unauthorized",
            text: "Report unauthorized transactions within 13 months to get a refund."
        )
    ]
}
