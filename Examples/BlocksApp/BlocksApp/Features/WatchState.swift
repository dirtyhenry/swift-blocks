import Blocks
import SwiftUI

@MainActor
class WatchState: ObservableObject {
    enum State: String {
        case pending = "⏳ Pending"
        case paired = "✔ Paired"
        case unpaired = "✘ Unpaired"
        case unknown = "🤷‍♂️ Unknown"
        case unavailable = "🚫 Watch Connectivity is iOS-only"
    }

    @Published var state: State = .pending

    func start() {
        #if os(iOS)
        // In a real app, call this one time from the app delegate.
        WatchPairingUtil.shared.activateSession()

        Task {
            let value = try? await UIDevice.current.isPairedWithWatch(timeoutAfter: 3)

            switch value {
            case .none:
                state = .unknown
            case .some(true):
                state = .paired
            case .some(false):
                state = .unpaired
            }
        }
        #else
        state = .unavailable
        #endif
    }
}
