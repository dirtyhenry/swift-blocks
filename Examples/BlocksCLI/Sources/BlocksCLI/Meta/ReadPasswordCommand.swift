import ArgumentParser
import Blocks
import Foundation

struct ReadPasswordCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "password",
        abstract: "Read a password from the cli."
    )

    mutating func run() throws {
        guard let password = CLIUtils.readLine(
            prompt: "Please enter a dummy password (it will be repeated in clear): ",
            secure: true
        ) else {
            print("No password was entered.")
            return
        }

        print("The password entered was: *\(password)*")
    }
}
