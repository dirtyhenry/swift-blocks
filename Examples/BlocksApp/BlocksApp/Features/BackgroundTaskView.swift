import os
import SwiftUI

struct BackgroundTaskView: View {
    var body: some View {
        Button("Start background activity") {
            Task {
                startNormalTask()
                startBackgroundTask()
            }
        }
    }

    func startNormalTask() {
        Task {
            await countTo(id: "normal", limit: 1000)
        }
    }

    func startBackgroundTask() {
        Task {
            let identifier = await UIApplication.shared.beginBackgroundTask {
                let logger = Logger(subsystem: "net.mickf.blocks", category: "DemoApp")
                logger.info("Background task expired.")
            }

            await countTo(id: "background", limit: 1000)

            await UIApplication.shared.endBackgroundTask(identifier)
        }
    }

    func countTo(id: String, limit: Int) async {
        let logger = Logger(subsystem: "net.mickf.blocks", category: "DemoApp")
        do {
            for index in 0 ... limit {
                try Task.checkCancellation()
                logger.info("ID \(id) Index \(index)")
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
            logger.info("ID \(id) completed")
        } catch {
            logger.info("ID \(id) was cancelled")
        }
    }
}

struct BackgroundTaskView_Previews: PreviewProvider {
    static var previews: some View {
        BackgroundTaskView()
    }
}
