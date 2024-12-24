import SwiftUI

public struct LabeledTextField: View {
  private var title: String
  @Binding var text: String
  
    public init(
        _ title: String,
        text: Binding<String>
    ) {
    self.title = title
    self._text = text
  }
  
  public var body: some View {
    ZStack(alignment: .leading) {
      if !text.isEmpty {
        Text(title)
          .foregroundColor(text.isEmpty ? Color(.placeholderText) : .accentColor)
          .offset(y: text.isEmpty ? 0 : -25)
          .scaleEffect(text.isEmpty ? 1: 0.8, anchor: .leading)
      }
      TextField("", text: $text)
    }
    .padding(.top, 16)
    .animation(.default, value: text)
  }
}

#Preview {
    Form {
        LabeledTextField("Input", text: .constant("Value"))
    }
}
