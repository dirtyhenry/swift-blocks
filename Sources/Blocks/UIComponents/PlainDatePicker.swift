#if canImport(SwiftUI)
import SwiftUI

public struct PlainDatePicker: View {
    private let titleKey: LocalizedStringKey
    private let selection: Binding<PlainDate>

    public init(
        _ titleKey: LocalizedStringKey,
        selection: Binding<PlainDate>
    ) {
        self.titleKey = titleKey
        self.selection = selection
    }

    public var body: some View {
        DatePicker(
            titleKey,
            selection: Binding(get: {
                selection.wrappedValue.date
            }, set: { date in
                selection.wrappedValue = PlainDate(date: date, calendar: selection.wrappedValue.calendar)
            }),
            displayedComponents: [.date]
        ).environment(\.calendar, selection.wrappedValue.calendar)
    }
}

#Preview {
    @State var plainDate: PlainDate = "2024-01-17"
    return PlainDatePicker("Date", selection: $plainDate)
}

#Preview("Compact") {
    if #available(iOS 14.0, *) {
        @State var plainDate: PlainDate = "2024-01-17"
        return PlainDatePicker("Date", selection: $plainDate).datePickerStyle(.compact)
    } else {
        return Text("Compact style available from iOS 14.0")
    }
}

#Preview("Graphical") {
    if #available(iOS 14.0, *) {
        @State var plainDate: PlainDate = "2024-01-17"
        return PlainDatePicker("Date", selection: $plainDate).datePickerStyle(.graphical)
    } else {
        return Text("Graphical style available from iOS 14.0")
    }
}

#Preview("Wheel") {
    @State var plainDate: PlainDate = "2024-01-17"
    return PlainDatePicker("Date", selection: $plainDate).datePickerStyle(.wheel)
}
#endif
