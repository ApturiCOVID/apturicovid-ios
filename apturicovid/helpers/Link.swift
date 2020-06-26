import Foundation

enum Link: String {
    case Privacy, Terms
    var url: URL {
        switch self {
        case .Privacy:
            return URL(string: "https://apturicovid.lv/privatuma-politika#\(Language.primary.localization)")!
        case .Terms:
            return URL(string: "https://apturicovid.lv/lietosanas-noteikumi#\(Language.primary.localization)")!
        }
    }
}
