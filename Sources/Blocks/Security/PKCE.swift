import CryptoKit
import Foundation

/// [Proof Key for Code Exchange by OAuth Public Clients RFC](https://datatracker.ietf.org/doc/html/rfc7636)
public enum PKCE {
    public struct ClientSeeds {
        public let codeVerifier: String

        // MARK: - Creating the verifier seed

        public init(octetsCount: Int = 32) throws {
            let randomOctets = try SecurityUtils.generateCryptographicallySecureRandomOctets(count: octetsCount)
            self.init(octets: randomOctets)
        }

        public init(octets: [UInt8]) {
            self.init(codeVerifier: DataFormatter.base64URLString(from: Data(octets)))
        }

        public init(codeVerifier: String) {
            self.codeVerifier = codeVerifier
        }

        // MARK: - Getting the code challenge

        public func codeChallenge() throws -> String {
            try Self.codeChallenge(verifier: codeVerifier)
        }

        public static func codeChallenge(verifier: String) throws -> String {
            let codeChallenge = verifier // String
                .data(using: .ascii) // Decode back to [UInt8] -> Data?
                .map { SHA256.hash(data: $0) } // Hash -> SHA256.Digest?
                .map { DataFormatter.base64URLString(from: $0) } // base64URLEncode

            return try codeChallenge ?? { throw SimpleMessageError(message: "") }()
        }
    }
}
