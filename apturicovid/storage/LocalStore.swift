import Foundation
import ExposureNotification

class LocalStore {
    static let shared = LocalStore()
    
    //MARK: Keychain:
    @KeychainValue(.phoneNumber, defaultValue: nil)
    var phoneNumber: PhoneNumber?
    
    func clearPrivateDataOnFirstLaunch(){
        guard isFirstAppLaunch else { return }
        clearPrivateData()
    }
    
    func clearPrivateData(){
        KeychainGlobalKey.allCases.forEach{
            KeychainService.removeData(key: $0.stringValue)
        }
    }
    
    //MARK: User Defaults:
    
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
    
    var isFirstAppLaunch: Bool {
        return !hasSeenIntro
    }
    
    @UserDefault(.exposureStateReminderEnabled, defaultValue: false)
    var exposureStateReminderEnabled: Bool
    
    @UserDefault(.notificationIdentifier, defaultValue: nil)
    var notificationIdentifier: String?
    
    func setMobilephoneAndScheduleUpload(phone: PhoneNumber?) {
        guard phone != nil else {
            phoneNumber = nil
            return
        }
        
        phoneNumber = phone
        BackgroundManager.shared.scheduleExposureUploadTask()
    }
}
