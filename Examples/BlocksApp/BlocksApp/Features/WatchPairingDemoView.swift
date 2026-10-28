import Blocks
import SwiftUI

@MainActor
final class WatchPairingModel: ObservableObject {
    enum Status: Equatable {
        case checking
        case paired
        case notPaired
        case unknown
    }

    @Published private(set) var status: Status = .checking
    @Published private(set) var responseTime: Duration?

    private var checkTask: Task<Void, Never>?

    /// Starts a new check. Cancels the check in progress, so that only the last check updates the status.
    func check() {
        #if os(iOS)
        checkTask?.cancel()
        status = .checking
        responseTime = nil
        checkTask = Task {
            let clock = ContinuousClock()
            let start = clock.now
            let isPaired = try? await UIDevice.current.isPairedWithWatch(timeoutAfter: 3)
            guard !Task.isCancelled else { return }
            responseTime = clock.now - start
            switch isPaired {
            case .none:
                status = .unknown
            case .some(true):
                status = .paired
            case .some(false):
                status = .notPaired
            }
        }
        #endif
    }

    func cancel() {
        checkTask?.cancel()
        checkTask = nil
    }
}

struct WatchPairingDemoView: View {
    @StateObject private var model = WatchPairingModel()

    var body: some View {
        #if os(iOS)
        Form {
            Section {
                LabeledContent("Apple Watch") {
                    statusLabel
                }
                if let responseTime = model.responseTime {
                    LabeledContent(
                        "Response Time",
                        value: responseTime.formatted(.units(allowed: [.seconds, .milliseconds]))
                    )
                }
            } footer: {
                Text("""
                The app activates the Watch Connectivity session at launch. \
                The check waits up to 3 seconds for the activation.
                """)
            }

            Section {
                Button("Check Again") {
                    model.check()
                }
                .disabled(model.status == .checking)
            }
        }
        .navigationTitle("Watch Pairing")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            model.check()
        }
        .onDisappear {
            model.cancel()
        }
        #else
        ContentUnavailableView(
            "Watch Connectivity Is Unavailable",
            systemImage: "applewatch.slash",
            description: Text("Run this demo on an iPhone.")
        )
        .navigationTitle("Watch Pairing")
        #endif
    }

    @ViewBuilder
    private var statusLabel: some View {
        switch model.status {
        case .checking:
            ProgressView()
        case .paired:
            Label("Paired", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .notPaired:
            Label("Not Paired", systemImage: "xmark.circle")
                .foregroundStyle(.secondary)
        case .unknown:
            Label("Unknown", systemImage: "questionmark.circle")
                .foregroundStyle(.orange)
        }
    }
}

#Preview {
    NavigationStack {
        WatchPairingDemoView()
    }
}
