import Foundation

#if os(macOS)
public class Sitemap {
    public enum ChangeFreq: String {
        case always
        case hourly
        case daily
        case weekly
        case monthly
        case yearly
        case never
    }

    let doc: XMLDocument

    public init() {
        let root = XMLElement(name: "urlset")
        root.setAttributesWith(["xmlns": "http://www.sitemaps.org/schemas/sitemap/0.9"])
        doc = XMLDocument(rootElement: root)
        doc.version = "1.0"
        doc.characterEncoding = "utf-8"
    }

    public func add(entry: URLEntry) {
        doc.rootElement()?.addChild(entry.xmlNode)
    }

    public func xmlString(options: XMLNode.Options = []) -> String {
        doc.xmlString(options: options)
    }

    public struct URLEntry {
        let location: URL
        let lastmod: PlainDate?
        let changeFreq: ChangeFreq?
        let priority: Priority?

        public init(
            location: URL,
            lastmod: PlainDate?,
            changeFreq: ChangeFreq?,
            priority: Priority?
        ) {
            self.location = location
            self.lastmod = lastmod
            self.changeFreq = changeFreq
            self.priority = priority
        }
    }

    public struct Priority {
        let value: Double

        public init(value: Double) {
            self.value = max(0.0, min(1.0, value))
        }
    }
}

extension Sitemap.Priority: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self.init(value: value)
    }
}

extension Sitemap.URLEntry {
    var xmlNode: XMLNode {
        let node = XMLElement(name: "url")
        node.addChild(XMLElement(name: "loc", stringValue: location.absoluteString))

        if let lastmod {
            node.addChild(XMLElement(name: "lastmod", stringValue: lastmod.description))
        }

        if let changeFreq {
            node.addChild(XMLElement(name: "changefreq", stringValue: changeFreq.rawValue))
        }

        if let priority {
            node.addChild(XMLElement(name: "priority", stringValue: priority.description))
        }

        return node
    }
}

extension Sitemap.Priority: CustomStringConvertible {
    public var description: String {
        let formatter = NumberFormatter()
        formatter.localizesFormat = false
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        formatter.roundingMode = .halfUp
        return formatter.string(for: value)!
    }
}
#endif
