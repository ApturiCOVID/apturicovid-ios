import Foundation

class InteropInfoUrlHelper {
    static func getLocalizedUrl() -> URL? {
        var urlString = ""
        
        switch Language.primary {
        case .LV:
            urlString = "https://www.spkc.gov.lv/lv/apturicovid-sadarbibas-valstis"
        case .EN:
            urlString = "https://www.spkc.gov.lv/lv/apturicovid-interoperability-countries"
        case .RU:
            urlString = "https://www.spkc.gov.lv/lv/apturicovid-strany-sotrudnichestva"
        }
        
        return URL(string: urlString)
    }
}
