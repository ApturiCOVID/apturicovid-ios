import Foundation

struct PhoneNumber: Codable {
    let number: String
    var otherParty: Bool
    var token: String?
}
