// Adapted Apple Exposure Manager
// https://developer.apple.com/documentation/exposurenotification/building_an_app_to_notify_users_of_covid-19_exposure

import Foundation
import ExposureNotification
import RxSwift

class ExposureManager {
    static let authorizationStatusChangeNotification = Notification.Name("ExposureManagerAuthorizationStatusChangedNotification")
    
    static let shared = ExposureManager()
    
    let manager = ENManager()
    var detectingExposures = false
    var enabled = true {
        didSet {
            manager.setExposureNotificationEnabled(detectingExposures) { (error) in
                if let error = error {
                    justPrintError(error)
                }
            }
        }
    }
    
    init() {
        manager.activate { _ in
            if ENManager.authorizationStatus == .authorized && !self.manager.exposureNotificationEnabled {
                self.manager.setExposureNotificationEnabled(true) { error in
                    if let err = error { justPrintError(err) }
                }
            }
        }
    }
    
    deinit {
        manager.invalidate()
    }
    
    static func getDefaultConfiguration() -> ENExposureConfiguration {
        let configuration = ENExposureConfiguration()
        configuration.minimumRiskScore = 0
        configuration.attenuationLevelValues = [1,2,3,4,5,6,7,8]
        configuration.attenuationWeight = 50
        configuration.daysSinceLastExposureLevelValues = [1,2,3,4,5,6,7,8]
        configuration.daysSinceLastExposureWeight = 50
        configuration.durationLevelValues = [1,2,3,4,5,6,7,8]
        configuration.durationWeight = 50
        configuration.transmissionRiskLevelValues = [1,2,3,4,5,6,7,8]
        configuration.transmissionRiskWeight = 50
        return configuration
    }
    
    func detectExposures(completionHandler: ((Bool) -> Void)? = nil) -> Progress {
        
        let progress = Progress()
        
        // Disallow concurrent exposure detection, because if allowed we might try to detect the same diagnosis keys more than once
        guard !detectingExposures else {
            completionHandler?(false)
            return progress
        }
        detectingExposures = true
        
        func finish(_ result: Result<([Exposure], Int), Error>) {
            
            let success: Bool
            
            if progress.isCancelled {
                success = false
            } else {
                switch result {
                case let .success((newExposures, nextDiagnosisKeyFileIndex)):
                    LocalStore.shared.nextDiagnosisKeyFileIndex = nextDiagnosisKeyFileIndex
                    LocalStore.shared.exposures.append(contentsOf: newExposures)
                    LocalStore.shared.exposures.sort { $0.date < $1.date }
                    LocalStore.shared.dateLastPerformedExposureDetection = Date()
                    LocalStore.shared.exposureDetectionErrorLocalizedDescription = nil
                    success = true
                case let .failure(error):
                    LocalStore.shared.exposureDetectionErrorLocalizedDescription = error.localizedDescription
                    // Consider posting a user notification that an error occured
                    success = false
                }
            }
            
            detectingExposures = false
            completionHandler?(success)
        }
        
        let nextDiagnosisKeyFileIndex = LocalStore.shared.nextDiagnosisKeyFileIndex
        
        RestClient.shared.getDiagnosisKeyFileURLs(startingAt: nextDiagnosisKeyFileIndex) { result in
            
            var localURLs: [URL] = []
            
            switch result {
            case let .success(urls):
                localURLs = urls
            case let .failure(error):
                finish(.failure(error))
            }
            
            ExposureManager.shared.manager.detectExposures(configuration: ExposureManager.getDefaultConfiguration(), diagnosisKeyURLs: localURLs) { (summary, error) in
                if let error = error {
                    finish(.failure(error))
                    return
                }
                let userExplanation = NSLocalizedString("USER_NOTIFICATION_EXPLANATION", comment: "User notification")
                ExposureManager.shared.manager.getExposureInfo(summary: summary!, userExplanation: userExplanation) { exposures, error in
                        if let error = error {
                            finish(.failure(error))
                            return
                        }
                        let newExposures = exposures!.map { exposure in
                            Exposure(date: exposure.date,
                                     duration: exposure.duration,
                                     totalRiskScore: exposure.totalRiskScore,
                                     transmissionRiskLevel: exposure.transmissionRiskLevel)
                        }
                        finish(.success((newExposures, nextDiagnosisKeyFileIndex + localURLs.count)))
                }
            }
        }
        
        return progress
    }
    
    func getDiagnosisKeys() -> Observable<[ENTemporaryExposureKey]> {
        return Observable.create { (observer) -> Disposable in
            self.manager.getDiagnosisKeys { (keys, error) in
                if let err = error {
                    observer.onError(err)
                    return
                }
                
                observer.onNext(keys ?? [])
            }
            return Disposables.create()
        }
    }
    
    func getTestDiagnosisKeys() -> Observable<[ENTemporaryExposureKey]> {
        return Observable.create { (observer) -> Disposable in
            self.manager.getTestDiagnosisKeys { (keys, error) in
                if let err = error {
                    observer.onError(err)
                    return
                }
                
                observer.onNext(keys ?? [])
            }
            return Disposables.create()
        }
    }
    
    func getAndPostDiagnosisKeys(code: String) -> Observable<Data> {
        return self.getDiagnosisKeys()
            .flatMap { (keys) -> Observable<Data> in
                return RestClient.shared.uploadDiagnosis(code: code, keys: keys)
            }
    }
    
    func getAndPostTestDiagnosisKeys(code: String) -> Observable<Data> {
        return self.getTestDiagnosisKeys()
            .flatMap { (keys) -> Observable<Data> in
                return RestClient.shared.uploadDiagnosis(code: code, keys: keys)
        }
    }
}
