import Foundation
import ExposureNotification

class LocalStore {
    static let shared = LocalStore()
    
    @UserDefault(.lastDownloadedBatchIndex, defaultValue: 0)
    var lastDownloadedBatchIndex: Int
    
    @UserDefault(.exposures, defaultValue: [])
    var exposures: [Exposure]
    
    @UserDefault(.dateLastPerformedExposureDetection, defaultValue: nil)
    var dateLastPerformedExposureDetection: Date?
    
    @UserDefault(.exposureDetectionErrorLocalizedDescription, defaultValue: nil)
    var exposureDetectionErrorLocalizedDescription: String?
    
    @UserDefault(.exposureNotificationsEnabled, defaultValue: false)
    var exposureNotificationsEnabled: Bool
    
    @UserDefault(.hasSeenIntro, defaultValue: false)
    var hasSeenIntro: Bool
    
    @UserDefault(.phoneNumber, defaultValue: nil)
    var phoneNumber: PhoneNumber?
    
    @UserDefault(.exposureStateReminderEnabled, defaultValue: false)
    var exposureStateReminderEnabled: Bool
    
    @UserDefault(.notificationIdentifier, defaultValue: nil)
    var notificationIdentifier: String?
}
