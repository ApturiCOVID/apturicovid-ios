import Foundation
import ExposureNotification

extension ENExposureConfiguration {
    convenience init(from configuration: ExposureConfiguration) {
        self.init()
        
        attenuationLevelValues = configuration.attenuationScores.map { NSNumber(value: $0) }
        daysSinceLastExposureLevelValues = configuration.daysSinceLastExposureScores.map { NSNumber(value: $0) }
        durationLevelValues = configuration.durationScores.map { NSNumber(value: $0) }
        transmissionRiskLevelValues = configuration.transmissionRiskScores.map { NSNumber(value: $0) }
        
        minimumRiskScore = UInt8(configuration.minimumRiskScore)
        attenuationWeight = Double(configuration.attenuationWeight)
        daysSinceLastExposureWeight = Double(configuration.daysSinceLastExposureWeight)
        durationWeight = Double(configuration.durationWeight)
        transmissionRiskWeight = Double(configuration.transmissionRiskWeight)
    }
}
