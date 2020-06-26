import Foundation

struct PhoneVerificationRequest: Codable {
    let phone_number: String
    let device_check_token: String
}
