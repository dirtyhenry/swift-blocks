@testable import Blocks
import XCTest

final class SwiftJSONFeedTests: XCTestCase {
    func makeSampleFeed() -> JSONFeed {
        var sampleFeed = JSONFeed(title: "My Example Feed",
                                  homePageURL: URL(string: "https://example.org/"),
                                  feedURL: URL(string: "https://example.org/feed.json"))

        sampleFeed.items.append(JSONFeed.Item(id: "1",
                                              url: URL(string: "https://example.org/initial-post"),
                                              contentHTML: "<p>Hello, world!</p>",
                                              contentText: nil))
        sampleFeed.items.append(JSONFeed.Item(id: "2",
                                              url: URL(string: "https://example.org/second-item"),
                                              contentHTML: nil,
                                              contentText: "This is a second item."))

        return sampleFeed
    }

    func testFeedJSONExport() throws {
        let sampleFeed = makeSampleFeed()
        let jsonFeedString = try JSONFeed.createEncoder().encode(sampleFeed)
        print("jsonFeedString: ", jsonFeedString)
        XCTAssertEqual(jsonFeedString.count, 360)
    }

    func testPerformanceExample() throws {
        let encoder = JSONFeed.createEncoder()
        let sampleFeed = makeSampleFeed()
        measure {
            for _ in 0 ... 100 {
                _ = try! encoder.encode(sampleFeed)
            }
        }
    }

    func testDecoding() throws {
        let sampleURL = Bundle.module.url(forResource: "sample-feed", withExtension: "json")
        let data = try Data(contentsOf: sampleURL!)
        let decoder = JSONFeed.createDecoder()
        let feed = try decoder.decode(JSONFeed.self, from: data)
        XCTAssertEqual(feed.title, "JSON Feed")
        XCTAssertEqual(feed.items.first!.datePublished, Date(timeIntervalSince1970: 1_596_818_676))
    }
}
