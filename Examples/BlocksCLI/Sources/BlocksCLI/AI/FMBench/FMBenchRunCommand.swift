#if canImport(FoundationModels)
import ArgumentParser
import Blocks
import Foundation
import FoundationModels

/// Runs the benchmark matrix and writes one JSON Lines record per call.
struct FMBenchRunCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "run",
        abstract: "Run tasks through the on-device model and log each call as JSON Lines."
    )

    @Option(help: "Folder of Markdown posts with front matter. Required for classify, tag, summarize and extract.")
    var corpus: String?

    @Option(help: "Tasks to run, comma-separated: classify, tag, summarize, extract, rewrite.")
    var tasks: String = BenchTask.allCases.map(\.rawValue).joined(separator: ",")

    @Option(help: "Configs to run, comma-separated, from A to F.")
    var configs: String = "A"

    @Option(help: "How many times to run each task on each item.")
    var runs: Int = 1

    @Option(help: "Seed for random sampling. Each iteration adds its index, unless --fixed-seed is set.")
    var seed: UInt64 = 42

    @Flag(help: "Use the same seed for every iteration, to test if a seed reproduces the output.")
    var fixedSeed = false

    @Option(help: "Keep only the first N posts of the corpus. Useful for a dry run.")
    var limit: Int?

    @Option(help: "Folder with <task>.txt and <task>-minimal.txt files that replace the built-in instructions.")
    var instructionsDir: String?

    @Flag(help: "Do not add the locale hint for posts that are not in English.")
    var noLocaleHint = false

    @Flag(help: "Skip the warm-up call before the first measured call.")
    var noWarmup = false

    @Option(help: "Output file. Records are appended.")
    var out: String = "fm-bench-results.jsonl"

    @Flag(name: .shortAndLong, help: "Print each output to stderr.")
    var verbose = false

    mutating func run() async throws {
        guard #available(macOS 26.0, *) else {
            throw SimpleMessageError(message: "macOS 26 required.")
        }
        try await Runner(command: self).run()
    }
}

@available(macOS 26.0, *)
private struct Runner {
    let command: FMBenchRunCommand
    let runId = UUID().uuidString.lowercased()
    let encoder = BenchRecord.makeEncoder()

    func run() async throws {
        try checkAvailability()
        let tasks = try parseTasks()
        let configs = try parseConfigs()
        let (posts, categories) = try loadPostsIfNeeded(tasks: tasks)
        let instructionsDir = command.instructionsDir.map { URL(fileURLWithPath: $0) }
        let environment = Environment(
            osVersion: ProcessInfo.processInfo.operatingSystemVersionString,
            modelVariant: Self.modelVariant(),
            contextSize: SystemLanguageModel.default.contextSize
        )

        let plan = buildPlan(tasks: tasks, configs: configs, posts: posts)
        log("fm-bench run \(runId): \(plan.count) calls, model \(environment.modelVariant), "
            + "context \(environment.contextSize), \(environment.osVersion)")

        if !command.noWarmup, let first = plan.first {
            log("warm-up call…")
            _ = try await makeCall(step: first, categories: categories, instructionsDir: instructionsDir).perform()
        }

        let handle = try openOutput()
        defer { try? handle.close() }
        let clock = ContinuousClock()
        for (index, step) in plan.enumerated() {
            let call = try makeCall(step: step, categories: categories, instructionsDir: instructionsDir)
            let start = clock.now
            let result = await call.perform()
            let latency = clock.now - start
            let latencyMs = Int(latency / .milliseconds(1))
            let record = makeRecord(
                step: step, call: call, result: result, latencyMs: latencyMs, environment: environment
            )
            let data = try encoder.encode(record)
            try handle.write(contentsOf: data)
            try handle.write(contentsOf: Data("\n".utf8))
            log("[\(index + 1)/\(plan.count)] \(step.itemId) \(step.task.rawValue) \(step.config.key) "
                + "#\(step.iteration) \(result.outcome.rawValue) \(latencyMs)ms")
            if command.verbose, let output = result.output ?? result.errorDescription {
                log("  " + output.replacingOccurrences(of: "\n", with: "\n  "))
            }
        }
        log("wrote \(plan.count) records to \(command.out)")
    }

    struct Environment {
        let osVersion: String
        let modelVariant: String
        let contextSize: Int
    }

    func makeRecord(
        step: Step,
        call: BenchCall,
        result: BenchCallResult,
        latencyMs: Int,
        environment: Environment
    ) -> BenchRecord {
        BenchRecord(
            runId: runId,
            timestamp: ISO8601DateFormatter().string(from: Date()),
            osVersion: environment.osVersion,
            modelVariant: environment.modelVariant,
            contextSize: environment.contextSize,
            itemId: step.itemId,
            task: step.task,
            config: step.config.key,
            iteration: step.iteration,
            language: step.language,
            instructionsStyle: step.config.instructions,
            outputMode: step.config.output,
            sampling: step.config.sampling,
            seed: call.seed,
            temperature: step.config.temperature,
            guardrails: step.config.guardrails,
            useCase: step.config.useCase,
            outcome: result.outcome,
            output: result.output,
            errorDescription: result.errorDescription,
            explanation: result.explanation,
            latencyMs: latencyMs,
            inputTokens: result.inputTokens,
            outputTokens: result.outputTokens,
            truthCategory: step.truthCategory,
            truthTags: step.truthTags,
            truthSummary: step.truthSummary
        )
    }

    // MARK: - Plan

    struct Step {
        let itemId: String
        let task: BenchTask
        let config: BenchConfig
        let iteration: Int
        let input: String
        let language: String?
        let truthCategory: String?
        let truthTags: [String]?
        let truthSummary: String?
    }

    func buildPlan(tasks: [BenchTask], configs: [BenchConfig], posts: [BenchPost]) -> [Step] {
        var plan: [Step] = []
        for config in configs {
            for task in tasks where config.tasks.contains(task) {
                if task == .rewrite {
                    for sample in BenchRewriteSample.all {
                        for iteration in 0 ..< command.runs {
                            plan.append(Step(
                                itemId: sample.id, task: task, config: config, iteration: iteration,
                                input: sample.text, language: nil,
                                truthCategory: nil, truthTags: nil, truthSummary: nil
                            ))
                        }
                    }
                } else {
                    for post in posts {
                        for iteration in 0 ..< command.runs {
                            plan.append(Step(
                                itemId: post.id, task: task, config: config, iteration: iteration,
                                input: post.body, language: post.language,
                                truthCategory: post.category, truthTags: post.tags, truthSummary: post.summary
                            ))
                        }
                    }
                }
            }
        }
        return plan
    }

    func makeCall(step: Step, categories: [String], instructionsDir: URL?) throws -> BenchCall {
        let instructions = try BenchInstructions.resolve(
            task: step.task,
            style: step.config.instructions,
            output: step.config.output,
            language: command.noLocaleHint ? nil : step.language,
            directory: instructionsDir
        )
        let seed: UInt64? = step.config.sampling == .greedy
            ? nil
            : (command.fixedSeed ? command.seed : command.seed &+ UInt64(step.iteration))
        return BenchCall(
            task: step.task,
            config: step.config,
            instructions: instructions,
            input: step.input,
            categories: categories,
            seed: seed
        )
    }

    // MARK: - Setup

    func checkAvailability() throws {
        switch SystemLanguageModel.default.availability {
        case .available:
            break
        case .unavailable(.deviceNotEligible):
            throw SimpleMessageError(message: "Device not eligible")
        case .unavailable(.appleIntelligenceNotEnabled):
            throw SimpleMessageError(message: "Apple Intelligence not enabled")
        case .unavailable(.modelNotReady):
            throw SimpleMessageError(message: "Model not ready")
        case let .unavailable(other):
            throw SimpleMessageError(message: "Model unavailable: \(other)")
        }
    }

    static func modelVariant() -> String {
        if #available(macOS 27.0, *) {
            return SystemLanguageModel.default.variant.displayName
        }
        return "AFM 2.x (pre-27 SDK runtime)"
    }

    func parseTasks() throws -> [BenchTask] {
        try command.tasks.split(separator: ",").map { raw in
            let name = raw.trimmingCharacters(in: .whitespaces)
            guard let task = BenchTask(rawValue: name) else {
                let known = BenchTask.allCases.map(\.rawValue).joined(separator: ", ")
                throw ValidationError("Unknown task '\(name)'. Use: \(known).")
            }
            return task
        }
    }

    func parseConfigs() throws -> [BenchConfig] {
        try command.configs.split(separator: ",").map { raw in
            let key = raw.trimmingCharacters(in: .whitespaces)
            guard let config = BenchConfig.named(key) else {
                let known = BenchConfig.all.map(\.key).joined(separator: ", ")
                throw ValidationError("Unknown config '\(key)'. Use: \(known).")
            }
            return config
        }
    }

    /// Loads the posts and the categories.
    ///
    /// The categories come from the whole corpus, not only from the first `--limit` posts.
    func loadPostsIfNeeded(tasks: [BenchTask]) throws -> (posts: [BenchPost], categories: [String]) {
        let needsCorpus = tasks.contains { BenchTask.corpusTasks.contains($0) }
        guard needsCorpus else { return ([], []) }
        guard let corpus = command.corpus else {
            throw ValidationError("--corpus is required for classify, tag, summarize and extract.")
        }
        let all = try BenchCorpus.load(directory: URL(fileURLWithPath: corpus))
        guard !all.isEmpty else {
            throw ValidationError("No .md or .mdx file found in \(corpus).")
        }
        let categories = Array(Set(all.compactMap(\.category))).sorted()
        let posts = command.limit.map { Array(all.prefix($0)) } ?? all
        return (posts, categories)
    }

    func openOutput() throws -> FileHandle {
        let url = URL(fileURLWithPath: command.out)
        if !FileManager.default.fileExists(atPath: url.path) {
            FileManager.default.createFile(atPath: url.path, contents: nil)
        }
        let handle = try FileHandle(forWritingTo: url)
        try handle.seekToEnd()
        return handle
    }

    func log(_ message: String) {
        FileHandle.standardError.write(Data((message + "\n").utf8))
    }
}
#endif
