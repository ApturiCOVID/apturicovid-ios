import Foundation

@propertyWrapper
public struct UserDefault<T> where T: Codable {
    private let key: UserDefaultKey
    private let defaultValue: T

    public init(_ key: UserDefaultKey, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }

    public var wrappedValue: T {
        get {
            if T.self == Int.self || T.self == Int?.self {
                return UserDefaults.standard.integer(forKey: key.rawValue) as! T
            } else if T.self == Bool.self || T.self == Bool?.self {
                return UserDefaults.standard.bool(forKey: key.rawValue) as! T
            } else if T.self == String.self || T.self == String?.self {
                return UserDefaults.standard.string(forKey: key.rawValue) as! T
            } else {
                let jsonDecoder = JSONDecoder()
                if let jsonData = UserDefaults.standard.data(forKey: key.rawValue) {
                    return (try? jsonDecoder.decode(T.self, from: jsonData)) ?? defaultValue
                }
                return defaultValue
            }
        }
        set {
            let thisIsNil: String? = nil
            if "\(newValue)" == "\(String(describing: thisIsNil))" {
                UserDefaults.standard.removeObject(forKey: key.rawValue)
            } else if T.self == Int.self || T.self == Int?.self {
                UserDefaults.standard.set(newValue, forKey: key.rawValue)
            } else if T.self == Bool.self || T.self == Bool?.self {
                UserDefaults.standard.set(newValue, forKey: key.rawValue)
            } else if T.self == String.self || T.self == String?.self {
                UserDefaults.standard.set(newValue, forKey: key.rawValue)
            } else {
                let jsonEncoder = JSONEncoder()
                let jsonData = try! jsonEncoder.encode(newValue)
                UserDefaults.standard.set(jsonData, forKey: key.rawValue)
            }
        }
    }
}

public enum UserDefaultKey: String {
    case hasSeenIntro
    case applicationLanguage
    case lastDownloadedBatchIndex
    case exposures
    case dateLastPerformedExposureDetection
    case exposureDetectionErrorLocalizedDescription
    case exposure
    case exposureNotificationsEnabled
    case phoneNumber
    case exposureStateReminderEnabled
    case notificationIdentifier
}
