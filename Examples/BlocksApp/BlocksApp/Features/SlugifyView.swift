import Blocks
import os
import OSLog
import SwiftUI

struct SlugifyView: View {
    @State private var input: String = ""
    @State private var slug: String = "".slugify()

    private let pasteboard = Pasteboard()

    var body: some View {
        Form {
            TextField(text: $input, prompt: Text("Input to Slugify")) {
                Text("Input")
            }.disableAutocorrection(true)
            #if os(macOS)
            LabeledContent {
                Text(slug)
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
        .onChange(of: input) { _, newValue in
            slug = newValue.slugify()
        }
        .navigationTitle("Slugify")
    }
}

#Preview {
    SlugifyView()
}
