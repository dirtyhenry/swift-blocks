#if canImport(FoundationModels)
import Foundation
import FoundationModels

@available(macOS 26.0, *)
@Generable(description: "Tags for a blog post.")
struct BenchTagResult {
    @Guide(description: "Up to five short tags, like the tags of a blog.", .maximumCount(5))
    var tags: [String]
}

@available(macOS 26.0, *)
@Generable(description: "A summary of a blog post.")
struct BenchSummaryResult {
    @Guide(description: "One sentence of at most 160 characters.")
    var short: String
    @Guide(description: "Three bullets with one fact each.", .count(3))
    var bullets: [String]
}

@available(macOS 26.0, *)
@Generable(description: "Facts named in a blog post.")
struct BenchFactsResult {
    @Guide(description: "Programming languages and frameworks named in the text.")
    var languagesAndFrameworks: [String]
    @Guide(description: "Tools, apps and services named in the text.")
    var tools: [String]
    @Guide(description: "Years written in the text, as four-digit numbers.")
    var years: [Int]
}

@available(macOS 26.0, *)
@Generable(description: "A rewrite of product copy.")
struct BenchRewriteResult {
    @Guide(description: "The rewritten copy.")
    var improved: String
    @Guide(description: "What changed, one short item each.", .maximumCount(3))
    var changes: [String]
}

/// The result of one call, before it becomes a ``BenchRecord``.
struct BenchCallResult {
    var outcome: BenchOutcome
    var output: String?
    var errorDescription: String?
    var explanation: String?
    var inputTokens: Int?
    var outputTokens: Int?
}

/// Runs one task on one input with a fresh session.
@available(macOS 26.0, *)
struct BenchCall {
    let task: BenchTask
    let config: BenchConfig
    let instructions: String
    let input: String
    let categories: [String]
    let seed: UInt64?

    static let refusalPrefixes = [
        "i'm sorry", "i am sorry", "sorry", "i cannot", "i can't", "i can’t", "as a language model", "as an ai"
    ]

    func makeModel() -> SystemLanguageModel {
        let useCase: SystemLanguageModel.UseCase = config.useCase == .contentTagging ? .contentTagging : .general
        let guardrails: SystemLanguageModel.Guardrails = config.guardrails == .permissive
            ? .permissiveContentTransformations
            : .default
        return SystemLanguageModel(useCase: useCase, guardrails: guardrails)
    }

    func makeOptions() -> GenerationOptions {
        let sampling: GenerationOptions.SamplingMode? = switch config.sampling {
        case .greedy: .greedy
        case .randomTop40: .random(top: 40, seed: seed)
        case .apiDefault: nil
        }
        return GenerationOptions(samplingMode: sampling, temperature: config.temperature)
    }

    func perform() async -> BenchCallResult {
        let session = LanguageModelSession(model: makeModel(), instructions: instructions)
        let options = makeOptions()
        do {
            switch (task, config.output) {
            case (.classify, _):
                let schema = try classificationSchema()
                let response = try await session.respond(to: input, schema: schema, options: options)
                return result(from: response, output: response.content.jsonString)
            case (.tag, _):
                let response = try await session.respond(to: input, generating: BenchTagResult.self, options: options)
                return result(from: response, output: response.rawContent.jsonString)
            case (.summarize, .guided):
                let response = try await session.respond(
                    to: input, generating: BenchSummaryResult.self, options: options
                )
                return result(from: response, output: response.rawContent.jsonString)
            case (.extract, _):
                let response = try await session.respond(to: input, generating: BenchFactsResult.self, options: options)
                return result(from: response, output: response.rawContent.jsonString)
            case (.rewrite, .guided):
                let response = try await session.respond(
                    to: input, generating: BenchRewriteResult.self, options: options
                )
                return result(from: response, output: response.rawContent.jsonString)
            case (.summarize, .text), (.rewrite, .text):
                let response = try await session.respond(to: input, options: options)
                var result = result(from: response, output: response.content)
                if Self.looksLikeRefusal(response.content) {
                    result.outcome = .softRefusal
                }
                return result
            }
        } catch {
            return await classify(error)
        }
    }

    /// A schema with one `category` property limited to the categories of the corpus.
    func classificationSchema() throws -> GenerationSchema {
        let category = DynamicGenerationSchema(name: "Category", anyOf: categories)
        let root = DynamicGenerationSchema(
            name: "Classification",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "category",
                    description: "The one category that fits the text best.",
                    schema: category
                )
            ]
        )
        return try GenerationSchema(root: root, dependencies: [])
    }

    private func result(from response: LanguageModelSession.Response<some Any>, output: String) -> BenchCallResult {
        var result = BenchCallResult(outcome: .success, output: output)
        if #available(macOS 27.0, *) {
            result.inputTokens = response.usage.input.totalTokenCount
            result.outputTokens = response.usage.output.totalTokenCount
        }
        return result
    }

    static func looksLikeRefusal(_ text: String) -> Bool {
        let head = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return refusalPrefixes.contains { head.hasPrefix($0) }
    }

    /// Maps both error families (27 and 26) to a ``BenchOutcome``.
    private func classify(_ error: Error) async -> BenchCallResult {
        var result = BenchCallResult(outcome: .error, errorDescription: String(describing: error))
        if #available(macOS 27.0, *), let error = error as? LanguageModelError {
            (result.outcome, result.explanation) = await outcome(of: error)
        } else if let error = error as? LanguageModelSession.GenerationError {
            (result.outcome, result.explanation) = await outcome(of: error)
        }
        return result
    }

    @available(macOS 27.0, *)
    private func outcome(of error: LanguageModelError) async -> (BenchOutcome, String?) {
        switch error {
        case .guardrailViolation: (.guardrail, nil)
        case let .refusal(refusal): await (.refusal, try? refusal.explanation.content)
        case .contextSizeExceeded: (.contextSize, nil)
        case .unsupportedLanguageOrLocale: (.unsupportedLanguage, nil)
        default: (.error, nil)
        }
    }

    private func outcome(of error: LanguageModelSession.GenerationError) async -> (BenchOutcome, String?) {
        switch error {
        case .guardrailViolation: (.guardrail, nil)
        case let .refusal(refusal, _): await (.refusal, try? refusal.explanation.content)
        case .exceededContextWindowSize: (.contextSize, nil)
        case .unsupportedLanguageOrLocale: (.unsupportedLanguage, nil)
        default: (.error, nil)
        }
    }
}
#endif
