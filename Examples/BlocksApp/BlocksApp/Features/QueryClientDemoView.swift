import Blocks
import SwiftUI

struct QueryClientDemoView: View {
    typealias Quote = DummyJSONClient.RandomQuote.Response

    let readme: LocalizedStringKey = """
    `QueryClient` caches async data and sends one request for concurrent queries with the same key.

    Tap **Fetch Quote**. For 5 seconds, the data is fresh: the client returns the cached quote and \
    sends no request. After 5 seconds, the data is stale: the client returns the cached quote \
    immediately and fetches a new one in the background. **Invalidate** clears the cache.
    """

    static let key = "random-quote"

    let client = QueryClient(
        defaultOptions: QueryOptions(staleTime: 5, cacheTime: 60)
    )

    @State var quote: Quote?
    @State var status: QueryStatus = .idle
    @State var isFetching = false
    @State var isStale = false
    @State var requestCount = 0
    @State var errorMessage: String?

    var body: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading) {
                Text(readme)
            }.frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            statusBadges

            Divider()

            quoteCard

            HStack(spacing: 16) {
                Button {
                    Task { await fetchQuote() }
                } label: {
                    Label("Fetch Quote", systemImage: "arrow.down.circle")
                }
                .buttonStyle(.borderedProminent)

                Button(role: .destructive) {
                    Task { await invalidate() }
                } label: {
                    Label("Invalidate", systemImage: "trash")
                }
                .buttonStyle(.bordered)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Query Client")
    }

    var statusBadges: some View {
        HStack(spacing: 12) {
            badge("Status", value: statusLabel, color: statusColor)
            badge("Fetching", value: isFetching ? "Yes" : "No", color: isFetching ? .orange : .secondary)
            badge("Data", value: isStale ? "Stale" : "Fresh", color: isStale ? .orange : .green)
            badge("Requests", value: "\(requestCount)", color: .secondary)
        }
    }

    var quoteCard: some View {
        VStack(spacing: 8) {
            if let quote {
                Text("\u{201C}\(quote.quote)\u{201D}")
                    .font(.body)
                    .italic()
                    .multilineTextAlignment(.center)
                Text("— \(quote.author)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            } else {
                Text("No quote loaded yet")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
    }

    func badge(_ title: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption)
                .bold()
                .foregroundStyle(color)
        }
    }

    var statusLabel: String {
        switch status {
        case .idle: "Idle"
        case .loading: "Loading"
        case .success: "Success"
        case .error: "Error"
        }
    }

    var statusColor: Color {
        switch status {
        case .idle: .secondary
        case .loading: .orange
        case .success: .green
        case .error: .red
        }
    }

    func fetchQuote() async {
        errorMessage = nil
        if quote == nil {
            status = .loading
        }

        do {
            // The client calls this closure only when it sends a request, so it counts the requests.
            quote = try await client.query(key: Self.key) {
                await MainActor.run { requestCount += 1 }
                return try await DummyJSONClient.defaultTransport.load(DummyJSONClient().randomQuote())
            }
            status = .success
        } catch {
            status = .error
            errorMessage = error.localizedDescription
        }

        await followBackgroundRefetch()
    }

    /// Shows the state of the query until the background refetch, if any, completes.
    func followBackgroundRefetch() async {
        while let state = await client.state(for: Self.key, as: Quote.self) {
            isFetching = state.isFetching
            isStale = state.isStale
            if let data = state.data {
                quote = data
            }
            guard state.isFetching else { return }
            try? await Task.sleep(for: .milliseconds(100))
        }
    }

    func invalidate() async {
        await client.invalidate(Self.key)
        quote = nil
        status = .idle
        isFetching = false
        isStale = false
        errorMessage = nil
    }
}

#Preview {
    NavigationStack {
        QueryClientDemoView()
    }
}
