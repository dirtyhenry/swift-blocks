import SwiftUI

@available(iOS 15.0, *)
@available(macOS 12.0, *)
public struct LabeledTextField: View {
    private var title: String
    @Binding var text: String
    private var prompt: Text?

    @FocusState private var fieldIsFocused: Bool

    public init(
        _ title: String,
        text: Binding<String>,
        prompt _: Text? = nil
    ) {
        self.title = title
        _text = text
    }

    public var body: some View {
        #if os(iOS)
        ZStack(alignment: .leading) {
            if !text.isEmpty || fieldIsFocused {
                Text(title)
                    .foregroundColor(text.isEmpty ? Color(.placeholderText) : .accentColor)
                    .offset(y: text.isEmpty ? 0 : -25)
                    .scaleEffect(text.isEmpty ? 1 : 0.8, anchor: .leading)
            }
            TextField("", text: $text, prompt: prompt)
                .focused($fieldIsFocused)
        }
        .padding(.top, 16)
        .animation(.default, value: text)
        #else
        TextField(title, text: $text, prompt: prompt)
        #endif
    }
}

#Preview {
    Form {
        if #available(iOS 15.0, macOS 12.0, *) {
            LabeledTextField("Input", text: .constant("Value"))
        } else {
            Text("macOS 12 is required.")
        }
    }
}
