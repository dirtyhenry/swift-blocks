import Blocks
import SwiftUI

class DummyJSONClient {
    static let defaultTransport: Transport = RetryTransport(
        wrapping: StatusCodeCheckingTransport(
            wrapping: LoggingTransport(
                wrapping: URLSession.shared,
                subsystem: "net.mickf.blocks"
            )
        )
    )

    enum RandomQuote {
        struct Response: Codable {
            let id: Int
            let quote: String
            let author: String
        }
    }

    func randomQuote() async throws -> Endpoint<RandomQuote.Response> {
        let url = try URL.dummyJSONURLComponents(path: "/quotes/random")
        return Endpoint(json: .get, url: url)
    }
}

extension URL {
    static func dummyJSONURLComponents(path: String) throws -> URL {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "dummyjson.com"
        urlComponents.path = path

        guard let url = urlComponents.url else {
            throw TransportError.unmetURLComponentsRequirements
        }

        return url
    }
}

struct TransportDemoView: View {
    @State var taskState: TaskState = .notStarted
    @State var quote: String?
    @State var author: String?

    var body: some View {
        VStack {
            TaskStateButton(
                "Load quote",
                runningTitleKey: "Loading quote…",
                action: {
                    Task {
                        do {
                            taskState = .running
                            let quoteResponse = try await DummyJSONClient.defaultTransport.load(
                                DummyJSONClient().randomQuote()
                            )
                            taskState = .completed
                            quote = quoteResponse.quote
                            author = quoteResponse.author
                        } catch {
                            taskState = .failed(errorDescription: error.localizedDescription)
                        }
                    }
                },
                disabledWhenCompleted: false,
                state: taskState
            )
            .buttonStyle(.borderedProminent)
            .padding(32)
            Text(quote ?? "")
            Text(author ?? "")
        }
    }
}

#Preview {
    TransportDemoView()
}
