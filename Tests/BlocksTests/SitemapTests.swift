@testable import Blocks
import XCTest

#if os(macOS)
    final class SitemapTests: XCTestCase {
        func testBasicUsage() throws {
            let sitemap = Sitemap()

            let urlEntry = Sitemap.URLEntry(
                location: URL(string: "http://www.example.com/")!,
                lastmod: "2005-01-02",
                changeFreq: .monthly,
                priority: 0.8
            )
            sitemap.add(entry: urlEntry)

            let outputXML = sitemap.doc.xmlString(options: .nodePrettyPrint)
            let expectedXML = """
            <?xml version="1.0" encoding="utf-8"?>
            <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
                <url>
                    <loc>http://www.example.com/</loc>
                    <lastmod>2005-01-02</lastmod>
                    <changefreq>monthly</changefreq>
                    <priority>0.80</priority>
                </url>
            </urlset>
            """

            XCTAssertEqual(outputXML, expectedXML)
        }
    }
#endif
