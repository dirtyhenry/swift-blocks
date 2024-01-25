import Blocks
import SwiftUI

struct FontName: Identifiable {
    var id: String
}

struct FontsView: View {
    @State private var searchText: String = ""

    let pasteboard = Pasteboard()
    let allFonts: [FontName]

    var filteredFonts: [FontName] {
        guard !searchText.isEmpty else { return allFonts }

        return allFonts.filter { font in
            font.id.lowercased().contains(searchText.lowercased())
        }
    }

    init() {
        #if canImport(UIKit)
        allFonts = UIFont
            .allFontNames()
            .map { FontName(id: $0) }
        #endif

        #if canImport(AppKit)
        allFonts = NSFont
            .allFontNames()
            .map { FontName(id: $0) }
        #endif
    }

    var body: some View {
        List(filteredFonts) { fontName in
            HStack {
                Text(fontName.id)
                    .font(.custom(fontName.id, size: 17.0, relativeTo: .body))
                Spacer()
                Button(action: {
                    pasteboard.copy(text: fontName.id)
                }, label: {
                    Image(systemName: "doc.on.doc")
                })
            }
        }
        .searchable(text: $searchText, prompt: "Search a font name")
        .navigationTitle("System fonts")
    }
}

struct FontsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            FontsView()
        }
    }
}
