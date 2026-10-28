import XCTest

extension XCTestCase {
    func isRunningOnCI() -> Bool {
        !isRunningOnDeveloperMachine()
    }

    func isRunningOnDeveloperMachine() -> Bool {
        #if os(iOS)
        ProcessInfo.processInfo.environment["SIMULATOR_HOST_HOME"]?.contains("mick") ?? false
        #elseif os(macOS)
        ProcessInfo.processInfo.environment["USER"] == "mick"
        #else
        true
        #endif
    }
}
