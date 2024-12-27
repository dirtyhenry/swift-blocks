import OSLog
import SwiftUI

@main
struct BlocksApp: App {
    @Environment(\.scenePhase) var scenePhase

    let logger = Logger(subsystem: "net.mickf.blocks", category: "App")

    var body: some Scene {
        WindowGroup {
            ContentView(model: WatchState())
        }.onChange(of: scenePhase) {
            switch scenePhase {
            case .active:
                logger.info("Active")
            case .background:
                logger.info("Background")
            case .inactive:
                logger.info("Inactive")
            @unknown default:
                logger.info("Unknown phase, please update switch expression.")
            }
        }
    }
}
