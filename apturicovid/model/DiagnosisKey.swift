import Foundation
import ExposureNotification

struct DiagnosisKey: Codable {
    let keyData: Data
    let rollingStartNumber: ENIntervalNumber
    let rollingPeriod: ENIntervalNumber
    let transmissionRiskLevel: ENRiskLevel
    
    enum CodingKeys: String, CodingKey {
        case keyData = "key_data"
        case rollingStartNumber = "rolling_start_number"
        case rollingPeriod = "rolling_period"
        case transmissionRiskLevel = "transmission_risk_level"
    }
}

extension DiagnosisKey {
    init(from exposureKey: ENTemporaryExposureKey) {
        keyData = exposureKey.keyData
        rollingStartNumber = exposureKey.rollingStartNumber
        rollingPeriod = exposureKey.rollingPeriod
        transmissionRiskLevel = exposureKey.transmissionRiskLevel
    }
}
