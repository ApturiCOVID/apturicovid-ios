import Foundation

extension NSError {
    static func make(_ message: String) -> Error {
        let dict: [String: Any] = [NSLocalizedDescriptionKey: message]
        return NSError(domain: Bundle.main.bundleIdentifier!, code: 0, userInfo: dict) as Error
    }
}
