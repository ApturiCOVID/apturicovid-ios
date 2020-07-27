import Foundation

struct Stats: Codable, Equatable {
    
    static let dateDecodingFormater: DateFormatter = {
        let formater = DateFormatter()
        formater.dateFormat = "yyyy-MM-dd"
        return formater
    }()
    
    static let datePreviewFormater: DateFormatter = {
        let formater = DateFormatter()
        formater.dateFormat = "dd.MM.yyyy"
        return formater
    }()
    
    enum DecodingError: String, Error { case invalidDate, decodingFailed }
    
    let totalTestsCount: Int
    let totalInfectedCount: Int
    let totalDeathCount: Int
    let totalRecoveredCount: Int
    let yesterdaysTestsCount: Int
    let yesterdaysInfectedCount: Int
    let yesterdayDeathCount: Int
    let updatedAt: Date
    
    var isOutdated: Bool {
        updatedAt.distance(to: Date()) > StatsClient.statTtlInterval
    }
    
    var dateString: String {
        Stats.datePreviewFormater.string(from: updatedAt)
    }
    
    static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom({ (decoder) -> Date in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)
            if let date = Stats.dateDecodingFormater.date(from: dateStr) { return date }
            throw Stats.DecodingError.invalidDate })
        return decoder
    }
    
    enum CodingKeys: String, CodingKey {
        case totalTestsCount = "total_tests_count"
        case totalInfectedCount = "total_infected_count"
        case totalDeathCount = "total_death_count"
        case totalRecoveredCount = "total_recovered_count"
        case yesterdaysTestsCount = "yesterday_tests_count"
        case yesterdaysInfectedCount = "yesterday_infected_count"
        case yesterdayDeathCount = "yesterday_death_count"
        case updatedAt = "updated_at"
    }
}
