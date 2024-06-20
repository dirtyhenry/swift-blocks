import Blocks
import SwiftUI

enum HorizontalAlignmentOption: Hashable {
    case center
    case leading

    func value() -> HorizontalAlignment {
        switch self {
        case .center:
            return .center
        case .leading:
            return .leading
        }
    }
}

struct TaskStateDemoView: View {
    let readme: LocalizedStringKey = """
    A `TaskStateButton` helps render 4 possible states of an asynchronous operation: not started, running, completed, and error.
    """

    @State var plainDate: PlainDate = .init(date: Date())
    @State var shouldSucceed: Bool = true
    @State var alignment: HorizontalAlignmentOption = .center

    @State var state: TaskState = .notStarted
    @State var durationInMs: Double = 1000

    let customDateFormatter: DateFormatter = {
        var res = DateFormatter()
        res.dateStyle = .full
        res.timeStyle = .none
        return res
    }()

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(alignment: .leading) {
                    Text(readme)
                }.frame(maxWidth: .infinity, alignment: .leading)
                Divider()
                VStack(alignment: .leading) {
                    Text("Params").font(.headline)
                    Toggle("Task should succeed?", isOn: $shouldSucceed)
                    Text("Task duration")
                    Slider(value: $durationInMs, in: 1000 ... 5000)
                    Text("Duration: \(Int(durationInMs))ms")
                        .font(.caption)
                    HStack {
                        Text("Error alignment")
                        Spacer()
                        Picker("Alignment", selection: $alignment) {
                            Text("Center").tag(HorizontalAlignmentOption.center)
                            Text("Leading").tag(HorizontalAlignmentOption.leading)
                        }
                    }
                }.frame(maxWidth: .infinity)
                Divider()
                VStack(alignment: .leading) {
                    Text("Preview").font(.headline)
                    Text(state.description)
                        .font(.caption)
                    HStack {
                        TaskStateButton(
                            "Start running",
                            runningTitleKey: "Running in progress…",
                            action: {
                                Task {
                                    state = .running
                                    try await Task.sleep(nanoseconds: UInt64(durationInMs * 1_000_000))
                                    state = shouldSucceed ? .completed : .failed(errorDescription: "Dummy error")
                                }
                            },
                            state: state,
                            alignment: alignment.value()
                        )
                        .buttonStyle(.borderedProminent)
                        .padding(32)
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color(white: 0.95))
                }.frame(maxWidth: .infinity, alignment: .leading)
                Divider()
                Button("Reset") {
                    state = .notStarted
                }.buttonStyle(BorderedButtonStyle())
            }.padding()
                .frame(maxWidth: .infinity)
        }.navigationTitle("TaskStateButton Demo")
    }
}

#Preview {
    TaskStateDemoView()
}
