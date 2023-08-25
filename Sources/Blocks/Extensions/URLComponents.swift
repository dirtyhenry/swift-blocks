import Foundation

public extension URLComponents {
    func queryItemValue(forName name: String) -> String? {
        queryItems?.first(where: { $0.name == name })?.value
    }
}
