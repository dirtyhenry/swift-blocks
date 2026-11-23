import Blocks
import BlocksUI
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

    struct AddProductRequest: Codable {
        let title: String
    }

    struct AddProductResponse: Codable {
        let id: Int
        let title: String
    }

    func randomQuote() async throws -> Endpoint<RandomQuote.Response> {
        let url = try URL.dummyJSONURLComponents(path: "/quotes/random")
        return Endpoint(json: .get, url: url)
    }

    func notFound() async throws -> Endpoint<RandomQuote.Response> {
        let url = try URL.dummyJSONURLComponents(path: "/http/404")
        return Endpoint(json: .get, url: url)
    }

    func addProduct(title: String) async throws -> Endpoint<AddProductResponse> {
        let url = try URL.dummyJSONURLComponents(path: "/products/add")
        return Endpoint(json: .post, url: url, body: AddProductRequest(title: title))
    }

    func slowQuote() async throws -> Endpoint<RandomQuote.Response> {
        let url = try URL.dummyJSONURLComponents(path: "/quotes/random")
        let delay = URLQueryItem(name: "delay", value: "3000")
        var endpoint = Endpoint<RandomQuote.Response>(json: .get, url: url, query: [delay])
        endpoint.request.timeoutInterval = 1
        return endpoint
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

    To see the logs, open Console.app. Choose **Action > Include Debug Messages**.
    Filter on the `net.mickf.blocks` subsystem.
    Select a message to see the body and the headers.
    Each retry is a new request, thus it gets a new number.
    """

    @State var taskState: TaskState = .notStarted
    @State var quote: String?
    @State var author: String?
    @State var otherRequestResult: String?

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
            Divider()
            HStack {
                Button("Send POST") {
                    run {
                        let product = try await load(DummyJSONClient().addProduct(title: "Blocks"))
                        return "Created product #\(product.id)"
                    }
                }
                Button("Get 404") {
                    run { try await load(DummyJSONClient().notFound()).quote }
                }
                Button("Time out") {
                    run { try await load(DummyJSONClient().slowQuote()).quote }
                }
            }
            .buttonStyle(.bordered)
            Text(otherRequestResult ?? "")
                .font(.caption)
            Spacer()
        }
        .padding()
        .navigationTitle("Transport Demo")
    }

    private func load<A>(_ endpoint: Endpoint<A>) async throws -> A {
        try await DummyJSONClient.defaultTransport.load(endpoint)
    }

    private func run(_ work: @escaping () async throws -> String) {
        Task {
            do {
                otherRequestResult = try await work()
            } catch {
                otherRequestResult = error.localizedDescription
            }
        }
    }
}

#Preview {
    TransportDemoView()
}
