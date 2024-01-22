import ArgumentParser
import Blocks
import Foundation
import os

struct DebugStandardInputCommand: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "debug-stdin",
        abstract: "Debug standard input reading."
    )

    mutating func run() async throws {
        let logger = Logger(subsystem: "net.mickf.blocks", category: "stdin")
        if #available(macOS 12.0, *) {
            logger.warning("DebugStandardInputCommand started")
            let fileHandle = FileHandle.standardInput
            let term = fileHandle.enableRawMode()
            defer { fileHandle.restoreRawMode(originalTerm: term) }

            for try await byte in fileHandle.bytes {
                logger.debug("Read byte: \(byte.description, privacy: .public)")
                print("\(byte.description)")
            }
        } else {
            logger.error("Yo")
            print("macOS 12 is required to run this command.")
        }
        logger.warning("DebugStandardInputCommand ended")
    }
}

extension FileHandle {
    func enableRawMode() -> termios {
        var raw = termios()
        tcgetattr(fileDescriptor, &raw)

        let original = raw
        raw.c_lflag &= ~UInt(ECHO | ICANON)
        tcsetattr(fileDescriptor, TCSADRAIN, &raw)
        return original
    }

    func restoreRawMode(originalTerm: termios) {
        var term = originalTerm
        tcsetattr(fileDescriptor, TCSADRAIN, &term)
    }
}
