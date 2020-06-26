import Foundation

struct ExposureWrapper: Codable {
    let uuid: String
    let exposure: Exposure
    var uploadetAt: Date?
    
    mutating func markUploaded() {
        uploadetAt = Date()
    }
}
