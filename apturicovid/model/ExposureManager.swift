// Adapted Apple Exposure Manager
// https://developer.apple.com/documentation/exposurenotification/building_an_app_to_notify_users_of_covid-19_exposure

import Foundation
import ExposureNotification
import RxSwift

class ExposureManager {
    static let authorizationStatusChangeNotification = Notification.Name("ExposureManagerAuthorizationStatusChangedNotification")
    
    static var shared = ExposureManager()
    
    static func reset() {
        Self.shared = ExposureManager()
    }
    
    var manager = ENManager()
    var exposureDetectionProgress: Progress?
    var enabled = LocalStore.shared.exposureNotificationsEnabled
    
    var detectingExposures = false
    
    init() {
        manager.activate { error in
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
    
    func refresh() {
        enabled = ENManager.authorizationStatus == .authorized && LocalStore.shared.exposureNotificationsEnabled
        LocalStore.shared.exposureNotificationsEnabled = enabled
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
                if !self.enabled {
                    NoticationsScheduler.shared.scheduleExposureStateNotification()
                } else {
                    NoticationsScheduler.shared.removeExposureStateReminder()
                }
                completable(.completed)
            }
            return Disposables.create { }
        }
    }
    
    func getDiagnosisKeys() -> Observable<[ENTemporaryExposureKey]> {
        var observable: Observable<[ENTemporaryExposureKey]>
        #if DEBUG
            observable = getTestDiagnosisKeys()
        #else
            observable = getReleaseDiagnosisKeys()
        #endif
        return observable
    }
    
    func getReleaseDiagnosisKeys() -> Observable<[ENTemporaryExposureKey]> {
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
                return ExposuresClient.shared.uploadDiagnosis(token: token, keys: keys)
        }
    }
    
    private func detectExposures(localUrls: [URL]) -> Observable<ENExposureDetectionSummary?> {
        return Observable.create { (observer) -> Disposable in
            let task = self.manager.detectExposures(configuration: ExposureManager.getDefaultConfiguration(), diagnosisKeyURLs: localUrls) { (summary, error) in
                guard error == nil else {
                    observer.onError(error!)
                    return
                }
                
                observer.onNext(summary)
            }
            return Disposables.create {
                task.cancel()
            }
        }
    }
    
    private func getExposureInfo(summary: ENExposureDetectionSummary) -> Observable<[ENExposureInfo]> {
        return Observable.create { (observer) -> Disposable in
            let task = self.manager.getExposureInfo(summary: summary, userExplanation: "some explanation") { (exposures, error) in
                guard error == nil else {
                    observer.onError(error!)
                    return
                }
                
                observer.onNext(exposures ?? [])
            }
            
            return Disposables.create {
                task.cancel()
            }
        }
    }
    
    func performExposureDetection() -> Observable<[ENExposureInfo]> {
        return ExposuresClient.shared.downloadDiagnosisBatches(startAt: 0)
            .flatMap { (urls) -> Observable<ENExposureDetectionSummary?> in
                return self.detectExposures(localUrls: urls)
            }
            .flatMap { (summary) -> Observable<[ENExposureInfo]> in
                guard let summary = summary else {
                    return Observable.just([])
                }
                
                return self.getExposureInfo(summary: summary)
            }
    }
    
    func performTestDetection() {
//        let binBase64 = "RUsgRXhwb3J0IHYxICAgIBoDMzEwIAEoATI7Ch9sdi5zcGtjLmdvdi5hcHR1cmljb3ZpZC5zdGFnaW5nGgJ2MSIDMzEwKg9TSEEyNTZ3aXRoRUNEU0E6HAoQlMC3Szc3u2qi0HTLQY5NYhAAGJDdoQEgkAE6HAoQd4WO3RUs+CWyYqOjnxKBGhAAGPDaoQEgkAE6HAoQOeRWKutEf2uR3OQBjK6NLBAAGIDcoQEgkAE="
//
//        let sigBase64 = "dGVzdA=="
//
//        let path = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
//
//        try? Data(base64Encoded: binBase64)!.write(to: path.appendingPathComponent("1.bin"))
//        try? Data(base64Encoded: sigBase64)!.write(to: path.appendingPathComponent("1.sig"))
//
////        let binPath = Bundle.main.url(forResource: "1", withExtension: "bin")!
////        let sigPath = Bundle.main.url(forResource: "1", withExtension: "sig")!
////
//        self.detectExposures(localUrls: [path.appendingPathComponent("1.bin"), path.appendingPathComponent("1.sig")]).subscribe(onNext: { exposures in
//            print(exposures)
//        }, onError: justPrintError)
//    }
        
        Observable.zip(
            ExposuresClient.shared.downloadFile(url: URL(string: "https://s3.us-east-1.amazonaws.com/apturicovid-development/dkfs/v1/2.bin")!),
            ExposuresClient.shared.downloadFile(url: URL(string: "https://s3.us-east-1.amazonaws.com/apturicovid-development/dkfs/v1/2.sig")!)
        )
            .flatMap({ (urls) -> Observable<ENExposureDetectionSummary?> in
                return ExposureManager.shared.detectExposures(localUrls: [urls.0])
            })
            .subscribe(onNext: { (summary) in
                print(summary)
            }, onError: justPrintError)
    }
}
