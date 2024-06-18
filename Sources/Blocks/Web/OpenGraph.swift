import Foundation

public struct OpenGraph: Codable {
    public let url: URL?
    public let title: String?
    public let description: String?
    public let image: URL?
    public let locale: String?
    public let type: ObjectType?

    public init(
        url: URL? = nil,
        title: String? = nil,
        description: String? = nil,
        image: URL? = nil,
        locale: String? = nil,
        type: ObjectType? = nil
    ) {
        self.url = url
        self.title = title
        self.description = description
        self.image = image
        self.locale = locale
        self.type = type
    }

    public enum ObjectType: String, Codable {
        case website
        case article
    }
}
