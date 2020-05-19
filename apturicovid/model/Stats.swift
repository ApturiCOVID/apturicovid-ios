import Foundation

class Stats: Codable {
    let totalTestsCount: Int
    let totalInfectedCount: Int
    let totalDeathCount: Int
    let infectedTestsProportion: Double
    let yesterdaysTestsCount: Int
    let yesterdaysInfectedCount: Int
    let yesterdayDeathCount: Int
//    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case totalTestsCount = "total_tests_count"
        case totalInfectedCount = "total_infected_count"
        case totalDeathCount = "total_death_count"
        case infectedTestsProportion = "infected_tests_proportion"
        case yesterdaysTestsCount = "yesterday_tests_count"
        case yesterdaysInfectedCount = "yesterday_infected_count"
        case yesterdayDeathCount = "yesterday_death_count"
//        case updatedAt = "updated_at"
    }
}
