import Foundation

class ExposureConfiguration: Codable {
    let minimumRiskScore: Int
    let attenuationScores: [Int]
    let attenuationWeight: Int
    let daysSinceLastExposureScores: [Int]
    let daysSinceLastExposureWeight: Int
    let durationScores: [Int]
    let durationWeight: Int
    let transmissionRiskScores: [Int]
    let transmissionRiskWeight: Int
    
    enum CodingKeys: String, CodingKey {
        case minimumRiskScore = "minimum_risk_score"
        case attenuationScores = "attenuation_scores"
        case attenuationWeight = "attenuation_weight"
        case daysSinceLastExposureScores = "days_since_last_exposure_scores"
        case daysSinceLastExposureWeight = "days_since_last_exposure_weight"
        case durationScores = "duration_scores"
        case durationWeight = "duration_weight"
        case transmissionRiskScores = "transmission_risk_scores"
        case transmissionRiskWeight = "transmission_risk_weight"
    }
}
