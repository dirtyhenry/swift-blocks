import Foundation

/// One Markdown post of the corpus, with its front matter as ground truth.
struct BenchPost: Codable, Sendable, Equatable {
    /// The file name without its extension.
    var id: String
    var title: String?
    var summary: String?
    var category: String?
    var tags: [String]
    /// The `language` front matter value, for example `fr`. `nil` when absent.
    var language: String?
    /// The Markdown body, without the front matter block.
    var body: String
    var wordCount: Int
}

/// Loads Markdown posts and reads their front matter.
///
/// The parser is small on purpose. It reads `key: value` lines, `- item` lists, and indented
/// continuation lines. This covers the front matter of a blog, not all of YAML.
enum BenchCorpus {
    /// Loads every `.md` and `.mdx` file in `directory`, sorted by file name.
    ///
    /// - Parameters:
    ///   - directory: The folder that holds the posts.
    ///   - limit: Keep only the first `limit` posts. `nil` keeps all of them.
    static func load(directory: URL, limit: Int? = nil) throws -> [BenchPost] {
        let fileManager = FileManager.default
        let names = try fileManager.contentsOfDirectory(atPath: directory.path)
            .filter { $0.hasSuffix(".md") || $0.hasSuffix(".mdx") }
            .sorted()
        var posts: [BenchPost] = []
        for name in names {
            if let limit, posts.count >= limit {
                break
            }
            let url = directory.appendingPathComponent(name)
            let markdown = try String(contentsOf: url, encoding: .utf8)
            let id = (name as NSString).deletingPathExtension
            posts.append(parse(id: id, markdown: markdown))
        }
        return posts
    }

    /// Splits `markdown` into front matter and body and builds a ``BenchPost``.
    static func parse(id: String, markdown: String) -> BenchPost {
        let (frontMatter, body) = split(markdown)
        let fields = parseFrontMatter(frontMatter)
        let trimmedBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
        return BenchPost(
            id: id,
            title: fields.scalars["title"],
            summary: fields.scalars["summary"],
            category: fields.scalars["category"],
            tags: fields.lists["tags"] ?? [],
            language: fields.scalars["language"],
            body: trimmedBody,
            wordCount: trimmedBody.split(whereSeparator: \.isWhitespace).count
        )
    }

    /// Returns the lines between the two `---` fences, and the text after the second fence.
    static func split(_ markdown: String) -> (frontMatter: [String], body: String) {
        var lines = markdown.components(separatedBy: "\n")
        guard lines.first?.trimmingCharacters(in: .whitespaces) == "---" else {
            return ([], markdown)
        }
        lines.removeFirst()
        guard let end = lines.firstIndex(where: { $0.trimmingCharacters(in: .whitespaces) == "---" }) else {
            return ([], markdown)
        }
        let frontMatter = Array(lines[..<end])
        let body = lines[(end + 1)...].joined(separator: "\n")
        return (frontMatter, body)
    }

    struct Fields: Equatable {
        var scalars: [String: String] = [:]
        var lists: [String: [String]] = [:]
    }

    /// Reads flat `key: value` pairs, `- item` lists and indented continuation lines.
    static func parseFrontMatter(_ lines: [String]) -> Fields {
        var fields = Fields()
        var currentKey: String?
        for rawLine in lines {
            if rawLine.trimmingCharacters(in: .whitespaces).isEmpty {
                continue
            }
            let isIndented = rawLine.hasPrefix(" ") || rawLine.hasPrefix("\t")
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if isIndented, let key = currentKey {
                if line.hasPrefix("- ") {
                    fields.lists[key, default: []].append(unquote(String(line.dropFirst(2))))
                } else if let existing = fields.scalars[key] {
                    fields.scalars[key] = existing + " " + unquote(line)
                } else {
                    fields.scalars[key] = unquote(line)
                }
                continue
            }
            guard let colon = line.firstIndex(of: ":") else { continue }
            let key = String(line[..<colon]).trimmingCharacters(in: .whitespaces)
            let value = String(line[line.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
            currentKey = key
            if value.isEmpty {
                continue
            }
            if value.hasPrefix("["), value.hasSuffix("]") {
                let inner = value.dropFirst().dropLast()
                fields.lists[key] = inner.split(separator: ",").map { unquote($0.trimmingCharacters(in: .whitespaces)) }
            } else {
                fields.scalars[key] = unquote(value)
            }
        }
        return fields
    }

    private static func unquote(_ value: String) -> String {
        guard value.count >= 2 else { return value }
        if (value.hasPrefix("\"") && value.hasSuffix("\"")) || (value.hasPrefix("'") && value.hasSuffix("'")) {
            return String(value.dropFirst().dropLast())
        }
        return value
    }
}
