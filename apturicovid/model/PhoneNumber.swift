import Foundation

struct PhoneNumber: Codable {
    let number: String
    let otherParty: Bool
    var token: String?
}
