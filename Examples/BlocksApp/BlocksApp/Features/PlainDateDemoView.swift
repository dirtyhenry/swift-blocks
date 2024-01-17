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

            LabeledContent("Formatted", value: plainDate.string(with: customDateFormatter))

            Divider()

            PlainDatePicker("Change the date", selection: $plainDate)
        }.padding()
    }
}

#Preview {
    PlainDateDemoView()
}
