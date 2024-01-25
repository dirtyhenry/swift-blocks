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
            #if os(iOS)
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
            #endif
        }
    }
}
