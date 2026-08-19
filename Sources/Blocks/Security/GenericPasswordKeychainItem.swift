#if canImport(Security)
import Foundation
import Security

private func throwIfNotSuccess(_ status: OSStatus) throws {
    guard status != errSecSuccess else { return }
    throw SecurityError.unhandledError(status: status)
}

extension Dictionary {
    func adding(key: Key, value: Value) -> Dictionary {
        var copy = self
        copy[key] = value
        return copy
    }
}

/// A convenience class to manage _generic password_ keychain items.
///
/// Items are stored with the default accessibility (`kSecAttrAccessibleWhenUnlocked`),
/// which is compatible with both ``Storage`` modes.
///
/// The keychain treats a local item and a synchronizable item with the same label and
/// account as two distinct items. An instance only ever reads, writes, or deletes the
/// item matching its own ``storage`` mode. See <doc:DataManagement> for a discussion of
/// the security tradeoffs between the two modes.
public final class GenericPasswordKeychainItem {
    /// Where a keychain item is stored, and whether it syncs across the user's devices.
    public enum Storage {
        /// The secret stays on this device only.
        ///
        /// It is never uploaded anywhere, but it is lost if the device is lost, wiped,
        /// or replaced.
        case localOnly

        /// The secret syncs via iCloud Keychain, end-to-end encrypted, to all devices
        /// signed into the same Apple ID with iCloud Keychain enabled.
        ///
        /// It survives the loss of any single device, at the cost of a wider exposure
        /// surface: every synced device, and the Apple ID account itself.
        case iCloud
    }

    /// The label of the keychain item.
    ///
    /// On macOS, as of version 14.1, the Keychain Access app calls this *Name*.
    public let label: String

    /// The account of the keychain item.
    public let account: String

    /// The storage mode of the keychain item.
    public let storage: Storage

    public init(label: String, account: String, storage: Storage = .localOnly) {
        self.label = label
        self.account = account
        self.storage = storage
    }

    var baseDictionary: [String: AnyObject] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account as CFString,
            kSecAttrLabel as String: label as CFString,
            kSecAttrSynchronizable as String: (storage == .iCloud ? kCFBooleanTrue : kCFBooleanFalse) as AnyObject
        ]
    }

    var query: [String: AnyObject] {
        baseDictionary.adding(key: kSecMatchLimit as String, value: kSecMatchLimitOne)
    }

    public func delete() throws {
        let status = SecItemDelete(baseDictionary as CFDictionary)
        guard status != errSecItemNotFound else { return }
        try throwIfNotSuccess(status)
    }

    public func read() throws -> String? {
        let query = query.adding(key: kSecReturnData as String, value: true as AnyObject)
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status != errSecItemNotFound else { return nil }
        try throwIfNotSuccess(status)
        guard let data = result as? Data, let string = String(data: data, encoding: .utf8) else {
            throw SecurityError.unexpectedData
        }
        return string
    }

    public func write(_ secret: String) throws {
        let currentValue = try read()
        if currentValue == nil {
            try add(secret)
        } else {
            try update(secret)
        }
    }

    private func update(_ secret: String) throws {
        let dictionary: [String: AnyObject] = [
            kSecValueData as String: secret.data(using: String.Encoding.utf8)! as AnyObject
        ]
        try throwIfNotSuccess(SecItemUpdate(baseDictionary as CFDictionary, dictionary as CFDictionary))
    }

    private func add(_ secret: String) throws {
        let dictionary = baseDictionary.adding(
            key: kSecValueData as String,
            value: secret.data(using: .utf8)! as AnyObject
        )
        try throwIfNotSuccess(SecItemAdd(dictionary as CFDictionary, nil))
    }
}
#endif
