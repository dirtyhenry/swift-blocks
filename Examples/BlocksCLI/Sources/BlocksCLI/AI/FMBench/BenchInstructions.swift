import Foundation

/// The instructions for each task, in two styles.
///
/// Apple's prompting guide asks for a role, one goal, and one to three paragraphs. The `role` style
/// follows that. The `minimal` style is one sentence, to measure what the role line buys.
enum BenchInstructions {
    static let blogRole = "You are an assistant that organizes a developer's blog. "
        + "The person gives you the text of one blog post."

    /// Built-in instructions. A file in `--instructions-dir` named `<task>.txt` or `<task>-minimal.txt`
    /// replaces them.
    static func builtIn(task: BenchTask, style: BenchInstructionsStyle, output: BenchOutputMode) -> String {
        switch style {
        case .role: role(task: task, output: output)
        case .minimal: minimal(task: task)
        }
    }

    static func role(task: BenchTask, output: BenchOutputMode) -> String {
        switch task {
        case .classify:
            "\(blogRole) Pick the one category that fits the post best."
        case .tag:
            "\(blogRole) Return up to five short tags: the technologies, products and topics named in the post. "
                + "Write each tag as it appears in the text, for example Swift or iOS."
        case .summarize where output == .text:
            "\(blogRole) Write a summary of the post in one sentence of at most 160 characters. "
                + "Use only facts from the text. Return only the summary."
        case .summarize:
            "\(blogRole) Write a summary of the post in one sentence of at most 160 characters, "
                + "and three bullets with one fact each. Use only facts from the text."
        case .extract:
            "\(blogRole) List the programming languages and frameworks, the tools and services, and the years "
                + "that the text names. List only what the text names."
        case .rewrite:
            "You are a copy editor for a product website. The person gives you one short piece of product copy. "
                + "Rewrite it so it is clear, plain and concise. Keep its meaning. "
                + (output == .text ? "Return only the rewritten copy." : "")
        }
    }

    static func minimal(task: BenchTask) -> String {
        switch task {
        case .classify: "Classify the text."
        case .tag: "Tag the text."
        case .summarize: "Summarize the text in one sentence."
        case .extract: "Extract the facts from the text."
        case .rewrite: "Rewrite the text."
        }
    }

    /// Apple documents this exact phrase for non-US locales.
    static func localeHint(language: String?) -> String? {
        guard let language, language != "en" else { return nil }
        let locale = switch language {
        case "fr": "fr_FR"
        case "de": "de_DE"
        case "es": "es_ES"
        case "it": "it_IT"
        default: language
        }
        return "The person's locale is \(locale)."
    }

    /// Resolves the instructions for one call: a file, or the built-in text, with the locale hint first.
    static func resolve(
        task: BenchTask,
        style: BenchInstructionsStyle,
        output: BenchOutputMode,
        language: String?,
        directory: URL?
    ) throws -> String {
        var text = builtIn(task: task, style: style, output: output)
        if let directory {
            let name = style == .minimal ? "\(task.rawValue)-minimal.txt" : "\(task.rawValue).txt"
            let url = directory.appendingPathComponent(name)
            if FileManager.default.fileExists(atPath: url.path) {
                text = try String(contentsOf: url, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        if let hint = localeHint(language: language) {
            return hint + "\n\n" + text
        }
        return text
    }
}
