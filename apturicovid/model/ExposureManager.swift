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
                return RestClient.shared.uploadDiagnosis(token: token, keys: keys)
        }
    }
    
    func backgroundDetection(completionHandler: ((Bool) -> Void)? = nil) -> Progress {
        
        let progress = Progress()
        
        guard !detectingExposures else {
            completionHandler?(false)
            return progress
        }
        detectingExposures = true
        
        var localURLs = [URL]()
        
        func finish(_ result: Result<[Exposure], Error>) {
            var success = false
            
            if progress.isCancelled {
                success = false
            } else {
                switch result {
                case let .success(newExposures):
                    if newExposures.count > 0 {
                        NoticationsScheduler.shared.sendExposureDiscoveredNotification()
                    }
                    LocalStore.shared.exposures.append(contentsOf: newExposures.map { ExposureWrapper(uuid: UUID().uuidString, exposure: $0, uploadetAt: nil) })
                    LocalStore.shared.exposures.sort { $0.exposure.date < $1.exposure.date }
                    success = true
                case let .failure(error):
                    justPrintError(error)
                    LocalStore.shared.exposureDetectionErrorLocalizedDescription = error.localizedDescription
                    success = false
                }
            }
            
            detectingExposures = false
            completionHandler?(success)
        }
        
        RestClient.shared.getDiagnosisKeyFileUrls(startingAt: LocalStore.shared.lastDownloadedBatchIndex) { result in
            let dispatchGroup = DispatchGroup()
            var localURLResults = [Result<URL, Error>]()
            
            switch result {
            case let .success(remoteUrls):
                for remoteUrl in remoteUrls {
                    dispatchGroup.enter()
                    RestClient.shared.downloadDiagnosisKeyFile(at: remoteUrl.0, index: remoteUrl.1) { result in
                        localURLResults.append(result)
                        dispatchGroup.leave()
                    }
                }
            case let .failure(error):
                finish(.failure(error))
                return
            }
            
            dispatchGroup.notify(queue: .main) {
                for result in localURLResults {
                    switch result {
                    case let .success(localURL):
                        localURLs.append(localURL)
                    case let .failure(error):
                        finish(.failure(error))
                        return
                    }
                }
                
                ExposureManager.shared.manager.detectExposures(configuration: ExposureManager.getDefaultConfiguration(), diagnosisKeyURLs: localURLs) { (summary, error) in
                    if let error = error {
                        finish(.failure(error))
                        return
                    }
                    
                    guard let summary = summary else {
                        finish(.failure(NSError.make("Summary missing")))
                        return
                    }
                    
                    let userExplanation = "exposure_notification_exaplanation".translated
                    ExposureManager.shared.manager.getExposureInfo(summary: summary, userExplanation: userExplanation) { (exposures, error) in
                        if let error = error {
                            finish(.failure(error))
                            return
                        }
                        
                        let newExposures = exposures?.map { Exposure(from: $0) } ?? []
                        finish(.success(newExposures))
                    }
                }
            }
        }
        
        return progress
    }
}
