import Blocks
import SwiftUI

class WatchState: ObservableObject {
    enum State: String {
        case pending = "⏳ Pending"
        case paired = "✔ Paired"
        case unpaired = "✘ Unpaired"
        case unknown = "🤷‍♂️ Unknown"
    }

    @Published var state: State = .pending

    func start() {
        Task {
            let value = try? await UIDevice.current.isPairedWithWatch(timeoutAfter: 3)

            await MainActor.run {
                switch value {
                case .none:
                    state = .unknown
                case .some(true):
                    state = .paired
                case .some(false):
                    state = .unpaired
                }
            }
        }
    }
}

struct ContentView: View {
    @ObservedObject var model: WatchState

    init(model: WatchState) {
        self.model = model
    }

    var body: some View {
        VStack {
            Text("Is a watch paired with this iPhone?")
            Text(model.state.rawValue)
        }
        .padding()
        .onAppear {
            model.start()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(model: WatchState())
    }
}
