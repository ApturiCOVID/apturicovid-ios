import Foundation

struct PhoneConfirmationRequest: Codable {
    let token: String
    let code: String
}
