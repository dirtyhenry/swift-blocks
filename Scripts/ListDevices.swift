#!/usr/bin/swift

/**
 * -----------------------------------------------------------------------------
 * Find Simulator UDID Script
 * -----------------------------------------------------------------------------
 *
 * Description:
 * This script helps locate and print the UDID (Unique Device Identifier) of an
 * available iOS, watchOS, or tvOS simulator. It filters simulators based on a
 * provided OS version string and device name. The script queries `xcrun simctl list`
 * for available devices.
 *
 * If a single, unique simulator matches the criteria, its UDID is printed to
 * standard output. If no simulators match, or if multiple simulators match (making
 * the choice ambiguous), an error message is printed to standard error. This
 * error message includes a list of all available simulators (OS, name, and UDID)
 * to help the user refine their search criteria.
 *
 *
 * How to Use:
 * 1. Save this script to a file, for example, `listDevices.swift`.
 * 2. Make the script executable:
 *    ```bash
 *    chmod +x listDevices.swift
 *    ```
 * 3. Run the script from your terminal:
 *    ```bash
 *    ./listDevices.swift "OS_VERSION" "DEVICE_NAME"
 *    ```
 *
 *
 * Arguments:
 *   "OS_VERSION": (String) The target OS version. The expected format is
 *                 "OSName Major.Minor" (e.g., "iOS 17.0", "watchOS 10.2", "tvOS 17.0").
 *   "DEVICE_NAME": (String) The exact name of the target simulator device as it
 *                  appears in Xcode or `simctl list` (e.g., "iPhone 15 Pro",
 *                  "Apple Watch Series 9 (45mm)", "Apple TV 4K (3rd generation)").
 *
 *
 * Examples:
 *
 * 1. Find the UDID for an iPhone 15 Pro running iOS 17.0:
 *    ```bash
 *    ./listDevices.swift "iOS 17.0" "iPhone 15 Pro"
 *    ```
 *    If a unique match is found, output will be its UDID:
 *    ```
 *    XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
 *    ```
 *
 * 2. Find the UDID for an Apple Watch Series 9 (45mm) running watchOS 10.0:
 *    ```bash
 *    ./listDevices.swift "watchOS 10.0" "Apple Watch Series 9 (45mm)"
 *    ```
 *    Output (if unique):
 *    ```
 *    YYYYYYYY-YYYY-YYYY-YYYY-YYYYYYYYYYYY
 *    ```
 *
 * 3. If no unique simulator is found (e.g., OS/device combination doesn't exist,
 *    or arguments are misspelled):
 *    ```bash
 *    ./listDevices.swift "iOS 99.0" "iPhone Future"
 *    ```
 *    The script will print to standard error:
 *    ```
 *    Could not find unique requested set. Consider updating to one of:
 *    AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA: tvOS 17.0, Apple TV 4K (3rd generation)
 *    BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB: watchOS 10.0, Apple Watch Series 9 (45mm)
 *    CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC: iOS 17.0, iPhone 15 Pro Max
 *    DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD: iOS 17.0, iPhone 15 Pro
 *    ... (list continues with all available simulators)
 *    ```
 *
 * 4. Incorrect number of arguments:
 *    ```bash
 *    ./listDevices.swift "iOS 17.0"
 *    ```
 *    Output (to standard output):
 *    ```
 *    Usage: ./listDevices.swift "os" "device"
 *    ```
 *
 *
 * Exit Codes:
 *   0: - Success: A unique simulator UDID was found and printed.
 *      - Argument Mismatch: An incorrect number of arguments was provided.
 *        The script prints the usage message to standard output and exits.
 *   1: - Error: No unique simulator found matching the criteria (error message to stderr).
 *      - Runtime Error: An error occurred during `xcrun simctl` execution or JSON parsing
 *        (error message typically to stderr via thrown error, script might terminate with non-zero status).
 *
 *
 * Notes:
 * - Device names and OS versions must be exact matches.
 * - The list of available simulators is fetched using `xcrun simctl list --json devices available`.
 *   Ensure this command works on your system and that you have simulators created.
 *
 * -----------------------------------------------------------------------------
 */

import Foundation

/* jscpd:ignore-start */
extension FileHandle: @retroactive TextOutputStream {
    public func write(_ string: String) {
        let data = Data(string.utf8)
        write(data)
    }
}

public struct SimpleMessageError: Error {
    let message: String

    public init(message: String) {
        self.message = message
    }
}

extension SimpleMessageError: LocalizedError {
    public var errorDescription: String? {
        message
    }
}

struct DeviceContainer: Codable {
    let devices: [String: [Simulator]]
}

struct Simulator: Codable, Equatable {
    let lastBootedAt: String?
    let dataPath: String
    let dataPathSize: Int
    let logPath: String
    let udid: String
    let isAvailable: Bool
    let logPathSize: Int?
    let deviceTypeIdentifier: String
    let state: String
    let name: String
}

struct ZipOSSimulator: Comparable, CustomStringConvertible {
    let osIdentifier: String
    let simulator: Simulator

    // MARK: - CustomStringConvertible

    var description: String {
        "\(simulator.udid): \(formattedOSAndSimulator)"
    }

    var formattedOS: String {
        (try? formatOSIdentifier(osIdentifier)) ?? "n/a"
    }

    var formattedOSAndSimulator: String {
        "\(formattedOS), \(simulator.name)"
    }

    // MARK: - Comparable

    static func < (lhs: ZipOSSimulator, rhs: ZipOSSimulator) -> Bool {
        lhs.formattedOSAndSimulator < rhs.formattedOSAndSimulator
    }

    private func formatOSIdentifier(_ identifier: String) throws -> String {
        let pattern = #"com\.apple\.CoreSimulator\.SimRuntime\.([a-zA-Z]+)-(\d+)-(\d+)"#

        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let nsrange = NSRange(identifier.startIndex ..< identifier.endIndex, in: identifier)

        if let match = regex?.firstMatch(in: identifier, options: [], range: nsrange) {
            if let osRange = Range(match.range(at: 1), in: identifier),
               let majorVersionRange = Range(match.range(at: 2), in: identifier),
               let minorVersionRange = Range(match.range(at: 3), in: identifier) {
                let os = identifier[osRange]
                let majorVersion = identifier[majorVersionRange]
                let minorVersion = identifier[minorVersionRange]

                return "\(os) \(majorVersion).\(minorVersion)"
            }
        }

        throw SimpleMessageError(message: "formatDeviceIdentifier could not format \(identifier)")
    }
}

@discardableResult func shell(_ command: String) throws -> String {
    let process = Process()
    let pipe = Pipe()

    process.standardOutput = pipe
    process.standardError = pipe
    process.arguments = ["-c", command]
    process.launchPath = "/bin/zsh"
    process.standardInput = nil
    try process.run()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    guard let output = String(data: data, encoding: .utf8) else {
        throw SimpleMessageError(message: "Could not read UTF8 output from command.")
    }

    process.waitUntilExit()

    guard process.terminationStatus == 0 else {
        throw SimpleMessageError(
            message: "Command failed with status \(process.terminationStatus)")
    }

    return output
}

func find(osName: String?, deviceName: String?, in rawOutput: String) throws -> [ZipOSSimulator] {
    try JSONDecoder()
        .decode(DeviceContainer.self, from: Data(rawOutput.utf8))
        .devices
        .reduce(into: [ZipOSSimulator]()) { partialResult, newItem in
            partialResult.append(
                contentsOf: newItem.value.map {
                    ZipOSSimulator(
                        osIdentifier: newItem.key,
                        simulator: $0
                    )
                })
        }
        .filter { osName == nil ? true : $0.formattedOS == osName }
        .filter { deviceName == nil ? true : $0.simulator.name == deviceName }
}

if CommandLine.argc != 3 {
    print("Usage: ./\(CommandLine.arguments[0]) \"os\" \"device\"")
    exit(1)
} else {
    do {
        let rawAvailableDevicesJSON = try shell("xcrun simctl list --json devices available")
        let filteredZippedResults = try find(
            osName: CommandLine.arguments[1], deviceName: CommandLine.arguments[2],
            in: rawAvailableDevicesJSON
        )

        if filteredZippedResults.count == 1 {
            print(filteredZippedResults.first!.simulator.udid)
        } else {
            var standardError = FileHandle.standardError
            print(
                "Could not find unique requested set. Consider updating to one of:",
                to: &standardError
            )
            // Sort available devices for consistent, user-friendly output
            let alternatives = try find(osName: nil, deviceName: nil, in: rawAvailableDevicesJSON)
                .sorted() // Sorts alphabetically by OS then device name
                .map(\.description)
            print(alternatives.joined(separator: "\n"), to: &standardError)
            exit(1)
        }
    } catch {
        var standardError = FileHandle.standardError
        print("Error: \(error.localizedDescription)", to: &standardError)
        exit(1)
    }
}

/* jscpd:ignore-end */
