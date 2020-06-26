import Foundation

struct ExposureUploadRequest: Codable {
    let exposure_token: String
    let is_relative_device: Bool
    let exposures: [Exposure]
}
