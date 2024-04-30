import XCTest

extension XCTestCase {
    func isRunningOnCI() -> Bool {
        !isRunningOnDeveloperMachine()
    }

    func isRunningOnDeveloperMachine() -> Bool {
        #if os(iOS)
        return ProcessInfo.processInfo.environment["SIMULATOR_HOST_HOME"]?.contains("mick") ?? false
        #elseif os(macOS)
        return ProcessInfo.processInfo.environment["USER"] == "mick"
        #else
        return true
        #endif
    }
}
