import Blocks
import SwiftUI

struct FontName: Identifiable {
    var id: String
}

struct FontsView: View {
    let allFonts: [FontName]

    init() {
        allFonts = UIFont
            .allFontNames()
            .map { FontName(id: $0) }
    }

    var body: some View {
        List(allFonts) { fontName in
            HStack {
                Text(fontName.id)
                    .font(.custom(fontName.id, size: 17.0, relativeTo: .body))
                Spacer()
                Button(action: {
                    print(fontName.id)
                }, label: {
                    Image(systemName: "doc.on.doc")
                })
            }
        }.navigationTitle("System fonts")
    }
}

struct FontsView_Previews: PreviewProvider {
    static var previews: some View {
        FontsView()
    }
}
