import Blocks
import SwiftUI

@available(iOS 15.0.0, macOS 12.0, *)
struct QueryClientDemoView: View {
    let readme: LocalizedStringKey = """
    `QueryClient` caches async data and deduplicates in-flight requests.

    Tap **Fetch Quote** to load from the network. Subsequent taps return \
    cached data instantly and refresh in the background \
    (stale-while-revalidate). **Invalidate** clears the cache.
    """

    let client = QueryClient(
        defaultOptions: QueryOptions(staleTime: 5, cacheTime: 60)
    )

    @State var quote: String?
    @State var author: String?
    @State var status: QueryStatus = .idle
    @State var isFetching = false
    @State var fetchCount = 0
    @State var cacheHit = false

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
        .navigationTitle("QueryClient demo")
    }

    var statusBadges: some View {
        HStack(spacing: 12) {
            badge("Status", value: statusLabel, color: statusColor)
            badge("Fetching", value: isFetching ? "Yes" : "No", color: isFetching ? .orange : .secondary)
            badge("Cache", value: cacheHit ? "Hit" : "Miss", color: cacheHit ? .green : .secondary)
            badge("Fetches", value: "\(fetchCount)", color: .secondary)
        }
    }

    var quoteCard: some View {
        VStack(spacing: 8) {
            if let quote {
                Text("\u{201C}\(quote)\u{201D}")
                    .font(.body)
                    .italic()
                    .multilineTextAlignment(.center)
                if let author {
                    Text("— \(author)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("No quote loaded yet")
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.lightGray))
        .cornerRadius(12)
    }

    func badge(_ title: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption)
                .bold()
                .foregroundColor(color)
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
        let dataBefore = await client.getQueryData("random-quote", as: DummyJSONClient.RandomQuote.Response.self)
        cacheHit = dataBefore != nil

        do {
            let transport = DummyJSONClient.defaultTransport
            let response: DummyJSONClient.RandomQuote.Response = try await client.query(
                key: "random-quote",
                transport: transport,
                endpoint: DummyJSONClient().randomQuote()
            )
            quote = response.quote
            author = response.author
            status = .success
        } catch {
            status = .error
        }

        fetchCount += 1

        if let state = await client.state(for: "random-quote", as: DummyJSONClient.RandomQuote.Response.self) {
            isFetching = state.isFetching
        }
    }

    func invalidate() async {
        await client.invalidate("random-quote")
        quote = nil
        author = nil
        status = .idle
        isFetching = false
        cacheHit = false
    }
}

#Preview {
    if #available(iOS 15.0.0, macOS 12.0, *) {
        NavigationStack {
            QueryClientDemoView()
        }
    }
}
