import Combine
import os
import SwiftUI
import WatchConnectivity

let logger = Logger(subsystem: "net.mickf.BlocksApp", category: "Watch")

class WatchPairingTask: NSObject {
    struct TimedOutError: Error, Equatable {}

    static var shared = WatchPairingTask()

    override private init() {
        logger.debug("Creating an instance of WatchPairingTask.")
        super.init()
    }

    private var activationContinuation: CheckedContinuation<Bool, Never>?

    func isPaired(
        timeoutAfter maxDuration: TimeInterval
    ) async throws -> Bool {
        logger.debug("Just called isPaired")
        return try await withThrowingTaskGroup(of: Bool.self) { group in
            group.addTask {
                try await self.doWork()
            }

            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(maxDuration * 1_000_000_000))
                try Task.checkCancellation()
                // We’ve reached the timeout.
                logger.error("Throwing timeout")
                throw TimedOutError()
            }

            // First finished child task wins, cancel the other task.
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }

    private func doWork() async throws -> Bool {
        let session = WCSession.default
        session.delegate = self

        return await withCheckedContinuation { continuation in
            activationContinuation = continuation
            session.activate()
        }
    }
}

extension WatchPairingTask: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith _: WCSessionActivationState, error: Error?) {
        logger.debug("Session activation did complete")

        if let error = error {
            logger.error("Session activation did complete with error: \(error.localizedDescription, privacy: .public)")
        }

        activationContinuation?.resume(with: .success(session.isPaired))
    }

    func sessionDidBecomeInactive(_: WCSession) {
        // Do nothing
    }

    func sessionDidDeactivate(_: WCSession) {
        // Do nothing
    }
}

class WatchState: ObservableObject {
    @Published var isPaired: Bool?

    func start() {
        Task {
            do {
                let value = try await WatchPairingTask.shared.isPaired(timeoutAfter: 1)
                await MainActor.run {
                    isPaired = value
                }
            } catch {
                print("WatchState caught an error.")
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
            Text(model.isPaired?.description ?? "…")
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
