import Blocks
import OSLog
import SwiftUI

struct SlugifyView: View {
    private let logger = Logger(subsystem: "net.mickf.BlocksDemoApp", category: "Slugify")

    @State private var input: String = ""
    @State private var slug: String = "".slugify()

    private let pasteboard = Pasteboard()

    var body: some View {
        Form {
            Section(header: Text("Creating a slug")) {
                TextField(text: $input, prompt: Text("Input to Slugify")) {
                    Text("Input")
                }.disableAutocorrection(true)
                #if os(macOS)
                LabeledContent {
                    if slug.isEmpty {
                        Text("empty")
                            .foregroundColor(Color.gray)
                    } else {
                        Text(slug)
                    }
                } label: {
                    Text("Slug")
                }
                #else
                Text(slug)
                #endif
                Button("Copy") {
                    pasteboard.copy(text: slug)
                }
            }
        }
        .onChange(of: input) { _, newValue in
            slug = newValue.slugify()
        }
        .navigationTitle("Slugify")
    }
}

#Preview {
    SlugifyView()
}
