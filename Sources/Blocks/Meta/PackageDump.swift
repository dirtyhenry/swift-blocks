import Foundation

public struct PackageDump: Codable {
    public struct Target: Codable {
        public let name: String
        public let type: String
    }

    public let name: String
    public let targets: [Target]
}
