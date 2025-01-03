#if os(iOS)
import Blocks
import OSLog
import SwiftUI

class BackgroundRunnerSingleton {
    static let readMe = """
    When clicking this button, 3 tasks are created:

    1. A *normal* task: a timer that will repeat 1000 times with a pause of 5 seconds;
    2. A *background*: same as the *normal* task but wrapped up in `beginBackgroundTask`;
    3. A *network* task that will poll a dummy API at the same interval.
    """

    static let shared = BackgroundRunnerSingleton()

    private let logger = Logger(subsystem: "net.mickf.blocks", category: "BackgroundXP")
    private let pollingInterval: Int = 5

    private var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?
    private var cancellableTask: Task<Bool, Never>?

    private init() {}

    func start() {
        observeTermination()
        startNormalTask()
        startBackgroundTask()
        pollDummyAPI()
    }

    private func observeTermination() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.logger.info("Received willTerminate notification")
        }
    }

    private func startNormalTask() {
        Task {
            await countTo(id: "normal", limit: 1000)
        }
    }

    private func startBackgroundTask() {
        cancellableTask = Task {
            self.backgroundTaskIdentifier = await UIApplication.shared.beginBackgroundTask {
                self.cancelBackgroundTask()
            }
            await countTo(id: "background", limit: 1000)
            return true
        }
    }

    private func cancelBackgroundTask() {
        logger.info("Background task expired.")
        cancellableTask?.cancel()
        if let identifier = backgroundTaskIdentifier {
            UIApplication.shared.endBackgroundTask(identifier)
        }
    }

    private func countTo(id: String, limit: Int) async {
        do {
            for index in 0 ... limit {
                try Task.checkCancellation()
                logger.info("ID \(id, privacy: .public) Index \(index)")
                for _ in 1 ... pollingInterval {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    try Task.checkCancellation()
                }
            }
            logger.info("ID \(id, privacy: .public) completed")
        } catch {
            logger.info("ID \(id, privacy: .public) was cancelled")
        }
    }

    private func pollDummyAPI() {
        let url = URL(string: "https://jsonplaceholder.typicode.com/todos/1")!

        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            if let error {
                print("Error: \(error.localizedDescription)")
            } else if let data {
                do {
                    _ = try JSONSerialization.jsonObject(with: data, options: [])
                    self.logger.info("Polling received data.")
                } catch {
                    print("Error parsing JSON: \(error.localizedDescription)")
                }
            }

            // Poll again after 1 second
            DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(self.pollingInterval)) {
                self.pollDummyAPI()
            }
        }
        logger.info("Polling \(url, privacy: .public)")
        task.resume()
    }
}

struct BackgroundTaskView: View {
    @State var state: TaskState = .notStarted

    var body: some View {
        VStack {
            Text(BackgroundRunnerSingleton.readMe)
            TaskStateButton("Start background activity", action: {
                state = .running
                Task {
                    BackgroundRunnerSingleton.shared.start()
                }
            }, state: state)
                .buttonStyle(.borderedProminent)
        }
    }
}

struct BackgroundTaskView_Previews: PreviewProvider {
    static var previews: some View {
        BackgroundTaskView()
    }
}
#endif
