import Foundation

/**
   A utility for encoding Codable objects into JSON strings and printing them.

   ## Usage

   Using default are encouraged:

   ```swift
   let jsonString = JSON.stringify(sampleCodable)
   JSON.print(sampleCodable)
   ```

   The naming is inspired by JavaScript's [`JSON.stringify()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/JSON/stringify).
 */
public enum JSON {
    public static let defautErrorOutput = "💥 JSON Encoding did not work"

    /**
       Encodes a Codable object into a JSON string.

       - Parameters:
         - codable: A Codable object to encode.
         - encoder: A JSON encoder to use for encoding the object. Default is a pretty-printing encoder.
         - defaultErrorOutput: A string to return in case of an encoding error. Default is "💥 JSON Encoding did not work."

       - Returns: A JSON string representing the encoded object or the `defaultErrorOutput` in case of an error.
     */
    public static func stringify(
        _ codable: Codable,
        encoder: JSONEncoder = .prettyEncoder(),
        defaultErrorOutput: String = defautErrorOutput
    ) -> String {
        do {
            let data = try encoder.encode(codable)
            guard let output = String(data: data, encoding: .utf8) else {
                return defaultErrorOutput
            }
            return output
        } catch {
            return defaultErrorOutput
        }
    }

    /**
       Prints the JSON representation of a Codable object.

       - Parameters:
         - codable: A Codable object to print.
         - encoder: A JSON encoder to use for encoding the object. Default is a pretty-printing encoder.
         - defaultErrorOutput: A string to return in case of an encoding error (not used in this function).
     */
    public static func print(
        _ codable: Codable,
        encoder: JSONEncoder = .prettyEncoder(),
        defaultErrorOutput: String = defautErrorOutput
    ) {
        Swift.print(stringify(codable, encoder: encoder, defaultErrorOutput: defaultErrorOutput))
    }
}
