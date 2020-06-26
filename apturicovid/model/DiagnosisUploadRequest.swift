import Foundation

struct DiagnosisUploadRequest: Codable {
    let token: String
    let diagnosisKeys: [DiagnosisKey]
    
    enum CodingKeys: String, CodingKey {
        case token
        case diagnosisKeys = "diagnosis_keys"
    }
}
