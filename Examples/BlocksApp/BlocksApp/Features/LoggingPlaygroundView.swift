import Blocks
import os
import OSLog
import SwiftUI

struct LoggingPlaygroundView: View {
    let logger = Logger(subsystem: "net.mickf.BlocksDemoApp", category: "LoggingPlayground")

    @State var wrappedLogEntries: [LogEntryIdentifiableWrapper] = []

    var body: some View {
        VStack {
            Text("Logging Playground")
            List(wrappedLogEntries) { wrappedLogEntry in
                Text(wrappedLogEntry.entry.composedMessage)
                    .foregroundStyle(wrappedLogEntry.color)
            }
            Button("Log something") {
                logger._debug("Hello logging playground", metadata: ["date": Date()])
                logger.info("INFO Hello logging playground")
                logger.warning("WARNING Hello logging playground")
                logger.error("ERROR Hello logging playground")
            }
            Button("Read logs") {
                readLogs()
            }
        }
    }

    func readLogs() {
        do {
            let logStore = try OSLogStore(scope: .currentProcessIdentifier)
            let logStoreEntries = try logStore.getEntries(
                // 📜 Help to write predicates
                // https://useyourloaf.com/blog/fetching-oslog-messages-in-swift/
                matching: .init(format: "(subsystem == %@) && (category IN %@)", "net.mickf.BlocksDemoApp", ["LoggingPlayground"])
            )

            wrappedLogEntries = logStoreEntries
                .enumerated()
                .map { LogEntryIdentifiableWrapper(id: $0.offset, entry: $0.element) }
        } catch {
            logger.error("Error")
        }
    }
}

#Preview {
    LoggingPlaygroundView()
}

struct LogEntryIdentifiableWrapper: Identifiable {
    let id: Int
    let entry: OSLogEntry

    var color: Color {
        if let logEntryLog = entry as? OSLogEntryLog {
            switch logEntryLog.level {
            case .undefined:
                return .gray
            case .debug:
                return .blue
            case .info:
                return .green
            case .notice:
                return .yellow
            case .error:
                return .red
            case .fault:
                return .black
            @unknown default:
                return .gray
            }
        }

        return .gray
    }
}

public extension Logger {
    func _debug(_ message: String, metadata: Codable) {
        debug("🟦 \(message) (\(JSON.stringify(metadata))")
    }
}
