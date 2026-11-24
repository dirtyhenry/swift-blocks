import Foundation

public extension Dictionary {
    /// Returns a dictionary with the same values under transformed keys.
    ///
    /// When two keys transform into the same new key, the last one visited wins.
    ///
    /// - Parameter transform: A closure that turns a key into its new key.
    /// - Returns: The dictionary under its new keys.
    func mapKey<NewKey: Hashable>(_ transform: (Key) throws -> NewKey) rethrows -> [NewKey: Value] {
        try reduce(into: [NewKey: Value]()) { partialResult, tuple in
            let newKey = try transform(tuple.key)
            partialResult[newKey] = tuple.value
        }
    }
}
