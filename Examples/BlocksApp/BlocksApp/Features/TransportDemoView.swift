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
    let readme: LocalizedStringKey = """
    A `Transport` can compose behaviors dealing with URL requests.

    The one demoed here will:

    1. **Load data** from the internet (`URLSession.shared`);
    2. **Log requests** and responses to OSLog (`LoggingTransport`);
    3. **Throw** if the status code is an error one (`StatusCodeCheckingTransport`);
    4. **Retry** the request if it failed a couple of times (`RetryTransport`).
    """

    @State var taskState: TaskState = .notStarted
    @State var quote: String?
    @State var author: String?

    var body: some View {
        VStack(spacing: 32) {
            VStack(alignment: .leading) {
                Text(readme)
            }.frame(maxWidth: .infinity, alignment: .leading)
            Divider()
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
            VStack {
                Text(quote ?? "")
                Text(author ?? "")
                    .font(.caption)
            }
            Spacer()
        }
        .padding()
        .navigationTitle("Transport Demo")
    }
}

#Preview {
    TransportDemoView()
}
