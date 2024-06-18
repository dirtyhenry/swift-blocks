@dynamicMemberLookup
struct FrontMatter: Codable {
    let feed: JSONFeed.Item
    let openGraph: OpenGraph?

    subscript<T>(dynamicMember keyPath: WritableKeyPath<JSONFeed.Item, T>) -> T { feed[keyPath: keyPath] }

    enum SubCodingKeys: String, CodingKey {
        // In case we want to use snakeCase everywhere, we just need to add the extra `_` here.
        case openGraph = "_openGraph"
    }

    public init(feed: JSONFeed.Item, openGraph: OpenGraph) {
        self.feed = feed
        self.openGraph = openGraph
    }

    init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: SubCodingKeys.self)
        self.openGraph = try values.decode(OpenGraph.self, forKey: .openGraph)
        self.feed = try JSONFeed.Item(from: decoder)
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: SubCodingKeys.self)
        try container.encode(openGraph, forKey: .openGraph)
        try feed.encode(to: encoder)
    }
}
