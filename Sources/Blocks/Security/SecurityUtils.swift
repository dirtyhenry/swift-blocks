#if canImport(Security)
import Foundation

public enum SecurityUtils {
    public static func generateCryptographicallySecureRandomOctets(count: Int) throws -> [UInt8] {
        var octets = [UInt8](repeating: 0, count: count)
        let status = SecRandomCopyBytes(kSecRandomDefault, octets.count, &octets)
        if status == errSecSuccess { // Always test the status.
            return octets
        } else {
            throw SecurityError.unhandledError(status: status)
        }
    }
}
#endif
