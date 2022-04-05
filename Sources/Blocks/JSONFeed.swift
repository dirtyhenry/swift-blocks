import Foundation

struct JSONFeed: Codable {
    static let version1_1: String = "https://jsonfeed.org/version/1.1"

    /// The URL of the version of the format the feed uses.
    let version: String

    /// The name of the feed, which will often correspond to the the name of the website.
    var title: String

    /// The URL of the resource that the feed describes.
    ///
    /// This should be considered required for feeds on the public web.
    var homePageURL: URL?

    /// The URL of the feed.
    ///
    /// It serves as the unique identifier for the feed.
    ///
    /// This should be considered required for feeds on the public web.
    var feedURL: URL?

    /// Provides more detail, beyond the title, on what the feed is about.
    var description: String?

    /// A description of the purpose of the feed.
    ///
    /// For people looking at the raw JSON, it should be ignored by feed readers.
    var userComment: String?

    /// The URL of a feed that provide the next *n* items.
    var nextURL: URL?

    /// The URL of an image for the feed.
    ///
    /// It should be squared and relatively large — such as 512 × 512.
    var icon: URL?

    /// The URL of an image for the feed suitable to be used in a source list.
    ///
    /// It should be squared and relatively small — such as 64 × 64.
    var favicon: URL?

    /// The feed authors.
    var authors: [Author]?

    /// The primary language for the feed.
    var language: String?

    /// Says whether or not the feed is finished — that is, wheter or not it will ever update again.
    var isExpired: Bool?

    /// Endpoints that can be used to subscribe to real-time notifications from the publisher of this feed.
    var hubs: [Hub]?

    /// The feed items.
    var items: [Item]

    struct Author: Codable {
        /// The author's name.
        var name: String?

        /// The URL of a site owned by the author.
        var url: URL?

        /// The URL for an image for the author
        ///
        /// It should be squared and relatively large — such as 512 × 512.
        var avatar: URL?
    }

    struct Hub: Codable {
        var type: String
        var url: URL
    }

    struct Item: Codable {
        /// Unique identifier for that item for that feed over time.
        ///
        /// A full URL of the resource described by the item makes a great identifier.
        let id: String

        /// The URL of the resource described by the item.
        var url: URL?

        /// This is the URL of a page elsewhere.
        ///
        /// This is especially useful for linkblogs.
        var externalURL: URL?

        /// Plain text title of the item.
        ///
        /// Microblogs can omit titles.
        var title: String?

        /// The HTML of the item.
        var contentHTML: String?

        /// The plain text of the item.
        var contentText: String?

        /// Plain text short text describing the item.
        var summary: String?

        /// The URL of the main image for the item.
        var image: URL?

        /// The URL of an image to use as a banner.
        var bannerImage: URL?

        /// The publication date.
        var datePublished: Date?

        /// The modification date.
        var dateModified: Date?

        /// The authors of the item.
        var authors: [Author]?

        /// The tags of the item.
        var tags: [String]?

        /// The language for this item.
        var language: String?

        /// Related resources.
        var attachments: [Attachment]?

        struct Attachment: Codable {
            /// The location of the attachment.
            var url: URL

            /// The type of the attachment.
            var mimeType: String

            /// A name for the attachment.
            var title: String?

            /// The size of the file, in bytes.
            var size: Int?

            /// How long it takes to listen or watch, when played at normal speed.
            var duration: TimeInterval

            enum CodingKeys: String, CodingKey {
                case url
                case mimeType
                case title
                case size = "sizeInBytes"
                case duration = "durationInSeconds"
            }
        }

        init(id: String,
             url: URL?,
             externalURL: URL? = nil,
             title: String? = nil,
             contentHTML: String?,
             contentText: String?,
             summary: String? = nil,
             image: URL? = nil,
             bannerImage: URL? = nil,
             datePublished: Date? = nil,
             dateModified: Date? = nil,
             authors: [Author]? = nil,
             tags: [String]? = nil,
             attachments: [Attachment]? = nil) {
            self.id = id
            self.url = url
            self.externalURL = externalURL
            self.title = title
            self.contentHTML = contentHTML
            self.contentText = contentText
            self.summary = summary
            self.image = image
            self.bannerImage = bannerImage
            self.datePublished = datePublished
            self.dateModified = dateModified
            self.authors = authors
            self.tags = tags
            self.attachments = attachments
        }
    }

    init(version: String = JSONFeed.version1_1,
         title: String,
         homePageURL: URL?,
         feedURL: URL?,
         description: String? = nil,
         userComment: String? = nil,
         nextURL: URL? = nil,
         icon: URL? = nil,
         favicon: URL? = nil,
         authors: [Author]? = nil,
         isExpired: Bool? = nil,
         items: [Item] = []) {
        self.version = version
        self.title = title
        self.homePageURL = homePageURL
        self.feedURL = feedURL
        self.description = description
        self.userComment = userComment
        self.nextURL = nextURL
        self.icon = icon
        self.favicon = favicon
        self.authors = authors
        self.isExpired = isExpired
        hubs = nil
        self.items = items
    }
}

@available(macOS 10.13, *)
extension JSONFeed {
    static func createEncoder() -> JSONEncoder {
        let result = JSONEncoder()
        result.dateEncodingStrategy = .javaScriptISO8601()
        result.keyEncodingStrategy = .convertToSnakeCase
        return result
    }

    static func createDecoder() -> JSONDecoder {
        let result = JSONDecoder.javaScriptISO8601()
        result.dateDecodingStrategy = .javaScriptISO8601()
        result.keyDecodingStrategy = .convertFromSnakeCase
        return result
    }
}
