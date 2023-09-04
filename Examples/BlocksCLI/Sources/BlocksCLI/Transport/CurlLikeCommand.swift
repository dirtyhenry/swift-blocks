import ArgumentParser
import Blocks
import Foundation

@available(macOS 10.15.0, *)
struct CurlLikeCommand: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "curl",
        abstract: "A curl-like command, implemented with Blocks."
    )

    @Argument(help: "URL to fetch.")
    var inputURL: String

    @Option(help: "HTTP Headers.")
    var headers: [String]

    mutating func run() async throws {
        guard let urlComponents = URLComponents(string: inputURL),
              let url = urlComponents.url
        else {
            fatalError("Unparsable URL: \(inputURL)")
        }

        var urlRequest = URLRequest(url: url)
        headers.forEach { rawHeader in
            let subheaders = rawHeader.split(separator: ":", maxSplits: 1)
                .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            guard subheaders.count == 2 else {
                fatalError("Unsupported header \(rawHeader)")
            }
            urlRequest.addValue(subheaders[1], forHTTPHeaderField: subheaders[0])
        }
        #if os(macOS)
            if #available(macOS 12.0, *) {
                let transport: Transport = URLSession.shared
                dump(urlRequest)
                let (data, response) = try await transport.send(urlRequest: urlRequest, delegate: nil)

                guard response.textEncodingName == "utf-8" else {
                    fatalError("Only UTF8 is supported for HTTP responses encoding")
                }

                guard let string = String(data: data, encoding: .utf8) else {
                    fatalError("No printable data sent")
                }
                print(string)
            } else {
                fatalError("macOS 12 is required to run this command.")
            }
        #endif
    }
}
