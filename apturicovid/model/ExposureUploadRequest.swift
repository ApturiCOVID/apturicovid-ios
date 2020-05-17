import Foundation

struct ExposureUploadRequest: Codable {
    let exposure_token: String
    let exposures: [Exposure]
}
