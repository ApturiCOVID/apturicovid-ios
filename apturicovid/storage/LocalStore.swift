import Foundation
import ExposureNotification

struct Exposure: Codable {
    let date: Date
    let duration: TimeInterval
    let totalRiskScore: ENRiskScore
    let transmissionRiskLevel: ENRiskLevel
}

class LocalStore {
    static let shared = LocalStore()
    
    @UserDefault(.nextDiagnosisKeyFileIndex, defaultValue: 0)
    var nextDiagnosisKeyFileIndex: Int
    
    @UserDefault(.exposures, defaultValue: [])
    var exposures: [Exposure]
    
    @UserDefault(.dateLastPerformedExposureDetection, defaultValue: nil)
    var dateLastPerformedExposureDetection: Date?
    
    @UserDefault(.exposureDetectionErrorLocalizedDescription, defaultValue: nil)
    var exposureDetectionErrorLocalizedDescription: String?
    
    @UserDefault(.exposureNotificationsEnabled, defaultValue: false)
    var exposureNotificationsEnabled: Bool
    
    @UserDefault(.isFirstLaunch, defaultValue: false)
    var isFirstLaunch
    
    @UserDefault(.phoneNumber, defaultValue: nil)
    var phoneNumber: PhoneNumber?
}
