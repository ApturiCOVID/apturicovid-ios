import Foundation
import ExposureNotification

struct Exposure: Codable {
    let date: Date
    let duration: TimeInterval
    let totalRiskScore: ENRiskScore
    let transmissionRiskLevel: ENRiskLevel
    let attenuationValue: ENAttenuation
    
    enum CodingKeys: String, CodingKey {
        case date
        case duration
        case totalRiskScore = "total_risk_score"
        case transmissionRiskLevel = "transmission_risk_level"
        case attenuationValue = "attenuation_value"
    }
}

extension Exposure {
    init(from exposure: ENExposureInfo) {
        date = exposure.date
        duration = exposure.duration
        totalRiskScore = exposure.totalRiskScore
        transmissionRiskLevel = exposure.transmissionRiskLevel
        attenuationValue = exposure.attenuationValue
    }
}

