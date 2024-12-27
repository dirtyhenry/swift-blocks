import Blocks
import OSLog
import SwiftUI

struct FormPlaygroundView: View {
    private let logger = Logger(subsystem: "net.mickf.BlocksDemoApp", category: "FormPlayground")

    @State var text: String = ""

    var body: some View {
        Form {
            Section(header: Text("Section")) {
                TextField("Standard", text: $text)
                LabeledTextField("Title", text: $text, prompt: Text("Prompt"))
            }
        }
        .navigationTitle("Form Playground")
    }
}

#Preview {
    FormPlaygroundView()
}
