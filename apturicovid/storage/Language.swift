import Foundation

enum Language: String, Codable, CaseIterable {
    case LV, EN, RU
    
    @UserDefault(.applicationLanguage, defaultValue: .LV)
    static var primary: Language {
        didSet {
            NotificationCenter.default.post(name: .languageDidChange, object: primary)
            NotificationsScheduler.ExposureNotification.allCases.forEach {
                NotificationsScheduler.shared.translatePendingNotifications(for: $0)
            }
        }
    }
    
    var isPrimary: Bool { self == Language.primary }
    var localization: String { self.rawValue.lowercased() }
}
