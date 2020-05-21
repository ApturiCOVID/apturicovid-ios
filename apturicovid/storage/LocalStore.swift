import Foundation
import ExposureNotification

class LocalStore {
    static let shared = LocalStore()
    
    @UserDefault(.lastDownloadedBatchIndex, defaultValue: 0)
    var lastDownloadedBatchIndex: Int
    
    @UserDefault(.exposures, defaultValue: [])
    var exposures: [ExposureWrapper]
    
    @UserDefault(.stats, defaultValue: nil)
    var stats: Stats?
    
    @UserDefault(.statsLastFetchTime, defaultValue: Date(timeIntervalSince1970: 0))
    var lastStatsFetchTime: Date
    
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
    
    @UserDefault(.bgJobCounter, defaultValue: 0)
    var bgJobCounter: Int
    
    func setMobilephoneAndScheduleUpload(phone: PhoneNumber?) {
        guard phone != nil else {
            phoneNumber = nil
            return
        }
        
        phoneNumber = phone
        BackgroundManager.shared.scheduleExposureUploadTask()
    }
}
