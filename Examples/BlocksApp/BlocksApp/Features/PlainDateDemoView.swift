import Blocks
import SwiftUI

struct PlainDateDemoView: View {
    @State var plainDate: PlainDate = .init(date: Date())

    let customDateFormatter: DateFormatter = {
        var res = DateFormatter()
        res.dateStyle = .full
        res.timeStyle = .none
        return res
    }()

    var body: some View {
        VStack {
            Text("The current date is:")
            Text(plainDate.description)
            PlainDatePicker("Change the date", selection: $plainDate)
            LabeledContent("Formatted", value: plainDate.string(with: customDateFormatter))

        }.padding()
    }
}

#Preview {
    PlainDateDemoView()
}
