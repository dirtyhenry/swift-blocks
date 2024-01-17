import Blocks
import SwiftUI

struct TaskStateDemoView: View {
    @State var plainDate: PlainDate = .init(date: Date())
    @State var shouldSucceed: Bool = true

    @State var state: TaskState = .notStarted
    @State var durationInMs: Double = 1000

    let customDateFormatter: DateFormatter = {
        var res = DateFormatter()
        res.dateStyle = .full
        res.timeStyle = .none
        return res
    }()

    var body: some View {
        VStack {
            Toggle("Success?", isOn: $shouldSucceed)
            Slider(value: $durationInMs, in: 1000 ... 5000)
            Text("Duration: \(Int(durationInMs))ms")
            TaskStateButton("Show how task state button works",
                            runningTitleKey: "Showing how task state button works",
                            action: {
                                Task {
                                    state = .running
                                    try await Task.sleep(nanoseconds: UInt64(durationInMs * 1_000_000))
                                    state = shouldSucceed ? .completed : .failed(errorDescription: "Dummy error")
                                }
                            },
                            state: state)
                .buttonStyle(.borderedProminent)
            Text(state.description)
            Button("Reset") {
                state = .notStarted
            }
        }.padding()
    }
}

#Preview {
    TaskStateDemoView()
}
