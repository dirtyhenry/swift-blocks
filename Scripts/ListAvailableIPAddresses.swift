#!/usr/bin/swift

import Darwin
import Foundation

/* jscpd:ignore-start */

func getPrivateIPv4Addresses() -> [String] {
    var addresses: [String] = []
    var ifaddr: UnsafeMutablePointer<ifaddrs>?

    guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
        return addresses
    }

    defer { freeifaddrs(ifaddr) }

    var ptr = firstAddr
    while true {
        let interface = ptr.pointee

        // Skip interfaces without an address (can happen for unconfigured interfaces)
        guard let addr = interface.ifa_addr else {
            guard let next = interface.ifa_next else { break }
            ptr = next
            continue
        }

        let family = addr.pointee.sa_family

        if family == UInt8(AF_INET) {
            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))

            if getnameinfo(addr, socklen_t(addr.pointee.sa_len),
                           &hostname, socklen_t(hostname.count),
                           nil, 0, NI_NUMERICHOST) == 0 {
                let ip = String(cString: hostname)
                if isPrivateIPv4(ip) {
                    addresses.append(ip)
                }
            }
        }

        guard let next = interface.ifa_next else { break }
        ptr = next
    }

    return addresses
}

func isPrivateIPv4(_ ip: String) -> Bool {
    let components = ip.split(separator: ".").compactMap { Int($0) }
    guard components.count == 4 else { return false }

    let (a, b) = (components[0], components[1])

    // 10.0.0.0/8
    if a == 10 { return true }
    // 172.16.0.0/12
    if a == 172, (16 ... 31).contains(b) { return true }
    // 192.168.0.0/16
    if a == 192, b == 168 { return true }

    return false
}

// Usage
let privateIPs = getPrivateIPv4Addresses()
print(privateIPs)

/* jscpd:ignore-end */
