import ArgumentParser
import Blocks
import Foundation

struct ListIPAddressesCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list-ips",
        abstract: "List all private IPv4 addresses on this device."
    )

    @Flag(name: .shortAndLong, help: "Output as JSON array.")
    var json = false

    mutating func run() throws {
        let addresses = getPrivateIPv4Addresses()

        if json {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(addresses)
            if let jsonString = String(data: data, encoding: .utf8) {
                print(jsonString)
            }
        } else {
            if addresses.isEmpty {
                print("No private IPv4 addresses found.")
            } else {
                for address in addresses {
                    print(address)
                }
            }
        }
    }
}
