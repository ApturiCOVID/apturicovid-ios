import Foundation

struct DiagnosisUploadRequest: Codable {
    let uploadCode: String
    let diagnosisKeys: [DiagnosisKey]
    
    enum CodingKeys: String, CodingKey {
        case uploadCode = "upload_code"
        case diagnosisKeys = "diagnosis_keys"
    }
}
