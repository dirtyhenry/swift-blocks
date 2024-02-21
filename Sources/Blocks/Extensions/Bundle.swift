import Foundation

/// Extension for Bundle providing convenience methods to load contents of resources.
public extension Bundle {
    // MARK: - Loading contents

    /// Loads the contents of a resource file with the given name and extension as a string.
    ///
    /// - Parameters:
    ///   - name: The name of the resource file.
    ///   - ext: The extension of the resource file.
    ///   - encoding: The string encoding used to interpret the file's contents. Default is UTF-8.
    /// - Returns: The contents of the resource file as a string.
    /// - Throws: An error if the resource file cannot be found or if there is an error reading its contents.
    func contents(
        ofResource name: String,
        withExtension ext: String,
        encoding: String.Encoding = .utf8
    ) throws -> String {
        guard let resourceURL = url(forResource: name, withExtension: ext) else {
            throw SimpleMessageError(message: "No URL found for resource \(name).\(ext)")
        }

        return try String(contentsOf: resourceURL, encoding: encoding)
    }

    /// Loads the contents of a resource file with the given name and extension as raw data.
    ///
    /// - Parameters:
    ///   - name: The name of the resource file.
    ///   - ext: The extension of the resource file.
    ///   - options: Options for reading the data. Default is no options.
    /// - Returns: The contents of the resource file as raw data.
    /// - Throws: An error if the resource file cannot be found or if there is an error reading its contents.
    func contents(
        ofResource name: String,
        withExtension ext: String,
        options: Data.ReadingOptions = []
    ) throws -> Data {
        guard let resourceURL = url(forResource: name, withExtension: ext) else {
            throw SimpleMessageError(message: "No URL found for resource \(name).\(ext)")
        }

        return try Data(contentsOf: resourceURL, options: options)
    }
}
