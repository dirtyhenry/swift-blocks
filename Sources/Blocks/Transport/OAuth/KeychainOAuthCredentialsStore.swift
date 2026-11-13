#if canImport(Security)
import Foundation

/// A store that keeps the credentials in the keychain.
///
/// The store writes the credentials as JSON in one _generic password_ keychain item. See
/// ``GenericPasswordKeychainItem`` for the storage modes.
@available(iOS 15.0.0, *)
@available(macOS 12.0, *)
public actor KeychainOAuthCredentialsStore: OAuthCredentialsStore {
    let item: GenericPasswordKeychainItem
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    /// Creates a store.
    ///
    /// - Parameters:
    ///   - label: The label of the keychain item. For example, the name of the provider.
    ///   - account: The account of the keychain item. For example, the user ID at the provider.
    ///   - storage: The storage mode of the keychain item. The default is ``GenericPasswordKeychainItem/Storage/localOnly``.
    public init(label: String, account: String, storage: GenericPasswordKeychainItem.Storage = .localOnly) {
        self.init(item: GenericPasswordKeychainItem(label: label, account: account, storage: storage))
    }

    /// Creates a store.
    ///
    /// - Parameter item: The keychain item that holds the credentials.
    public init(item: GenericPasswordKeychainItem) {
        self.item = item
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    public func load() throws -> OAuthCredentials? {
        guard let json = try item.read() else { return nil }
        return try decoder.decode(OAuthCredentials.self, from: Data(json.utf8))
    }

    public func save(_ credentials: OAuthCredentials) throws {
        let data = try encoder.encode(credentials)
        guard let json = String(data: data, encoding: .utf8) else {
            throw SecurityError.unexpectedData
        }
        try item.write(json)
    }

    public func clear() throws {
        try item.delete()
    }
}
#endif
