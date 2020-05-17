// Adapted Apple Exposure Manager
// https://developer.apple.com/documentation/exposurenotification/building_an_app_to_notify_users_of_covid-19_exposure

import Foundation
import ExposureNotification
import RxSwift

class ExposureManager {
    static let authorizationStatusChangeNotification = Notification.Name("ExposureManagerAuthorizationStatusChangedNotification")
    
    static let shared = ExposureManager()
    
    var manager = ENManager()
    var exposureDetectionProgress: Progress?
    var enabled = LocalStore.shared.exposureNotificationsEnabled
    
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
    
    func toggleExposureNotifications(enabled: Bool) -> Completable {
        return Completable.create { (completable) -> Disposable in
            self.manager.setExposureNotificationEnabled(enabled) { (error) in
                guard error == nil else {
                    completable(.error(error!))
                    return
                }
                
                self.enabled = enabled
                LocalStore.shared.exposureNotificationsEnabled = enabled
                completable(.completed)
            }
            return Disposables.create { }
        }
    }
    
    func resetManager() {
        self.manager.invalidate()
        self.manager = ENManager()
    }
    
    func detectExposures() -> Observable<[ENExposureInfo]> {
        let nextDiagnosisKeyFileIndex = LocalStore.shared.lastDownloadedBatchIndex
        
        return RestClient.shared.downloadDiagnosisBatches(startAt: nextDiagnosisKeyFileIndex)
            .flatMap({ (urls) -> Observable<ENExposureDetectionSummary?> in
                return self.performDetection(urls: urls.compactMap{$0})
            })
            .flatMap { (summary) -> Observable<[ENExposureInfo]> in
                guard let summary = summary else {
                    return Observable.error(NSError.make("Exposure summary is empty"))
                }
                return self.getExposurySummaryInfo(summary: summary)
        }.do(onNext: { (exposures) in
            LocalStore.shared.exposures += exposures.map({ Exposure(from: $0) })
            if exposures.count > 0 {
                NoticationsScheduler.shared.sendExposureDiscoveredNotification()
            }
            self.resetManager()
        }, onError: { error in
            self.resetManager()
        })
    }
    
    func performDetection(urls: [URL]) -> Observable<ENExposureDetectionSummary?> {
        return Observable.create { (observer) -> Disposable in
            self.exposureDetectionProgress = self.manager.detectExposures(configuration: Self.getDefaultConfiguration(), diagnosisKeyURLs: urls) { (summary, error) in
                if let error = error {
                    observer.onError(error)
                } else {
                    observer.onNext(summary)
                }
            }
            
            return Disposables.create()
        }
    }
    
    func getExposurySummaryInfo(summary: ENExposureDetectionSummary) -> Observable<[ENExposureInfo]> {
        return Observable.create { (observer) -> Disposable in
            self.manager.getExposureInfo(summary: summary, userExplanation: "USER EXPLANATION") { (exposures, error) in
                if let error = error {
                    observer.onError(error)
                } else {
                    observer.onNext(exposures ?? [])
                }
            }
            
            return Disposables.create()
        }
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
    
    func getAndPostDiagnosisKeys(token: String) -> Observable<Data> {
        return self.getDiagnosisKeys()
            .flatMap { (keys) -> Observable<Data> in
                return RestClient.shared.uploadDiagnosis(token: token, keys: keys)
            }
    }
    
    func getAndPostTestDiagnosisKeys(token: String) -> Observable<Data> {
        return self.getTestDiagnosisKeys()
            .flatMap { (keys) -> Observable<Data> in
                return RestClient.shared.uploadDiagnosis(token: token, keys: keys)
        }
    }
}
