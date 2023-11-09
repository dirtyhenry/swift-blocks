import os
import SwiftUI

class BackgroundRunnerSingleton {
    static let shared = BackgroundRunnerSingleton()

    private let pollingInterval: Int = 5
    
    private var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?
    private var cancellableTask: Task<Bool, Never>?

    private init() {}

    func startNormalTask() {
        Task {
            await countTo(id: "normal", limit: 1000)
        }
    }

    func startBackgroundTask() {
        cancellableTask = Task {
            self.backgroundTaskIdentifier = await UIApplication.shared.beginBackgroundTask {
                self.cancelBackgroundTask()
            }
            await countTo(id: "background", limit: 1000)
            return true
        }
    }

    func cancelBackgroundTask() {
        let logger = Logger(subsystem: "net.mickf.blocks", category: "DemoApp")
        logger.info("Background task expired.")
        cancellableTask?.cancel()
        if let identifier = self.backgroundTaskIdentifier {
            UIApplication.shared.endBackgroundTask(identifier)
        }
    }

    func countTo(id: String, limit: Int) async {
        let logger = Logger(subsystem: "net.mickf.blocks", category: "DemoApp")
        do {
            for index in 0 ... limit {
                try Task.checkCancellation()
                logger.info("ID \(id) Index \(index)")
                for _ in 1 ... pollingInterval {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    try Task.checkCancellation()                }
            }
            logger.info("ID \(id, privacy: .public) completed")
        } catch {
            logger.info("ID \(id, privacy: .public) was cancelled")
        }
    }

    func pollDummyAPI() {
        let logger = Logger(subsystem: "net.mickf.blocks", category: "DemoApp")
        let url = URL(string: "https://jsonplaceholder.typicode.com/todos/1")!

        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            if let error {
                print("Error: \(error.localizedDescription)")
            } else if let data {
                do {
                    _ = try JSONSerialization.jsonObject(with: data, options: [])
                    logger.info("Polling received data.")
                } catch {
                    print("Error parsing JSON: \(error.localizedDescription)")
                }
            }

            // Poll again after 1 second
            DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(self.pollingInterval)) {
                self.pollDummyAPI()
            }
        }
        logger.info("Polling \(url)")
        task.resume()
    }
}

struct BackgroundTaskView: View {
    var body: some View {
        Button("Start background activity") {
            Task {
                BackgroundRunnerSingleton.shared.startNormalTask()
                BackgroundRunnerSingleton.shared.startBackgroundTask()
                BackgroundRunnerSingleton.shared.pollDummyAPI()
            }
        }
    }
}

struct BackgroundTaskView_Previews: PreviewProvider {
    static var previews: some View {
        BackgroundTaskView()
    }
}
