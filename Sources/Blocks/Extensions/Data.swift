import Foundation

public extension Data {
    init(
        contentsOfFileWithPath path: String,
        options: Data.ReadingOptions = []
    ) throws {
        let inputFileURL = URL(fileURLWithPath: path)
        try self.init(contentsOf: inputFileURL, options: options)
    }
}
