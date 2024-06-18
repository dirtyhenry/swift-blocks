@testable import Blocks
import XCTest

final class FrontMatterTests: XCTestCase {
    func makeSampleFrontMatter() -> FrontMatter {
        let frontMatter = FrontMatter(
            feed: .init(
                id: "my-post",
                url: URL(string: "https://example.org/my-post")!,
                title: "My Post",
                contentHTML: "<html>Content</html>",
                contentText: "# Content"
            ),
            openGraph: .init(
                url: URL(string: "https://example.org/my-post-og")!,
                title: "My Post",
                description: "A summary",
                locale: "fr-FR",
                type: .article
            )
        )
        return frontMatter
    }

    func testFrontMatterEncoding() throws {
        let sut = makeSampleFrontMatter()
        let json = JSON.stringify(sut, encoder: JSONFeed.createEncoder())
        print(json)
        XCTAssertEqual(json.count, 275)
    }

    func testFrontMatterDecoding() throws {
        let frontMatter = """
        {
          "id": "my-post",
          "url": "https://example.org/my-post",
          "title": "My Post",
          "content_html": "<html>Content</html>",
          "content_text": "# Content",
          "_open_graph": {
            "title": "My Post",
            "locale": "fr-FR",
            "type": "article",
            "description": "A summary",
            "url": "https://example.org/my-post-og"
          }
        }
        """

        let sut = try JSONFeed.createDecoder().decode(FrontMatter.self, from: Data(frontMatter.utf8))
        XCTAssertEqual(sut.feed.title, "My Post")
        XCTAssertEqual(sut.openGraph?.title, "My Post")
    }
}
