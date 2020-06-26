import Foundation

struct ExposureConfiguration: Codable {
    let attenuationScores: [Int]
    let daysSinceLastExposureScores: [Int]
    let durationScores: [Int]
    let transmissionRiskScores: [Int]
    
    let minimumRiskScore: Int
    let attenuationWeight: Int
    let daysSinceLastExposureWeight: Int
    let durationWeight: Int
    let transmissionRiskWeight: Int
    
    let attenuationThreshold: [Int]
    
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
        case attenuationThreshold = "attenuation_threshold"
    }
}
