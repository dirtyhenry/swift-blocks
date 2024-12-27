#if canImport(SwiftUI)
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
            Text(title)
                .foregroundColor((text.isEmpty && !fieldIsFocused) ? Color(.placeholderText) : .accentColor)
                .offset(y: (text.isEmpty && !fieldIsFocused) ? 0 : -20)
                .scaleEffect((text.isEmpty && !fieldIsFocused) ? 1 : 0.6, anchor: .leading)
            TextField("", text: $text, prompt: prompt)
                .focused($fieldIsFocused)
                .offset(y: (text.isEmpty && !fieldIsFocused) ? 0 : 4)
        }
        .padding(.vertical, 4)
        .animation(.default)
        #else
        TextField(title, text: $text, prompt: prompt)
        #endif
    }
}

@available(iOS 18.0, *)
@available(macOS 14.0, *)
#Preview {
    @Previewable @State var text = ""
    return Form {
        LabeledTextField("Input 1", text: $text)
        TextField("Input to blur", text: $text)
    }
}
#endif
