import Foundation

public enum CLIUtils {
    /// Reads a line of input from the user.
    ///
    /// This method is a proxy to either `getpass` for secure input, or Swift's `readLine` otherwise.
    ///
    /// - Parameters:
    ///    - prompt: The prompt for the user's input.
    ///    - secure: A boolean value that determines whether the input should be read securely.
    ///
    /// - Returns: A String containing the user input if successful, or nil if an error occurred or if there is no available input.
    public static func readLine(prompt: String, secure: Bool) -> String? {
        if secure {
            return String(cString: getpass(prompt))
        } else {
            print(prompt)
            return Swift.readLine()
        }
    }
}
