import Foundation
import ExposureNotification
import RxSwift

class ExposureManager {
    
    enum StateError: Error {
        case bluetoothDisabled, unauthorized
        static func from(enError: Error?) -> StateError? {
            guard let error = enError as? ENError else { return nil }
            return error.code == .notAuthorized ? StateError.unauthorized : nil
        }
    }
    
    static let authorizationStatusChangeNotification = Notification.Name("ExposureManagerAuthorizationStatusChangedNotification")
    static let shared = ExposureManager()
    static var authorizationStatus: ENAuthorizationStatus { ENManager.authorizationStatus }
    
    private var enManager = ENManager()
    private var exposureDetectionProgress: Progress?
    private var detectingExposures = false
    private var enManagerActivated = false { didSet { emitTrackingEnabledStatus() } }
    private var statusObservation: NSKeyValueObservation?
    private var enabledObservation: NSKeyValueObservation?
    private let disposeBag = DisposeBag()
    
    private let TrackingIsWorkingSubject = BehaviorSubject<Bool>(value: LocalStore.shared.exposureNotificationsEnabled )
    var trackingIsWorkingObserver: Observable<Bool> { TrackingIsWorkingSubject.asObservable().share() }
    var trackingIsWorking: Bool { (try? TrackingIsWorkingSubject.value()) ?? false }
    
    /// Bluetooth status reported by Exposure manager.
    /// Note: this may not match the state of Bluetooth as reported by CoreBluetooth.
    var bluetoothEnabled: Bool { enManager.exposureNotificationStatus != .bluetoothOff }
    
    /// Indicates if Exposure Notification is enabled on the system. Must be used after Exposure manager successfult activated.
    var exposureNotificationEnabled: Bool? {
        guard enManagerActivated else { return nil}
        return enManager.exposureNotificationEnabled
    }
    
    private init(){
        activateENManager()
        NotificationCenter.default.rx
        .notification(UIApplication.didBecomeActiveNotification)
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: { [weak self] (_) in
            self?.emitTrackingEnabledStatus(enabled: LocalStore.shared.exposureNotificationsEnabled)
        }, onError: justPrintError)
        .disposed(by: disposeBag)
    }
    deinit { enManager.invalidate() }
    
    /// Resets Exposure detecion manager and relevant properties
    func reset() {
        enManager.invalidate()
        enManager = ENManager()
        exposureDetectionProgress = nil
        detectingExposures = false
        activateENManager()
    }
    
    /// Activates ENManager and subscribes to status updates
    private func activateENManager(){
        
        enManagerActivated = false
        
        enManager.activate { [weak self] error in
            
            if error == nil {
                self?.enManagerActivated = true
                
                self?.statusObservation = self?.enManager.observe(\.exposureNotificationStatus) { [weak self] (manager, change) in
                    self?.emitTrackingEnabledStatus()
                }
                
                self?.enabledObservation = self?.enManager.observe(\.exposureNotificationEnabled) { [weak self] (manager, change) in
                    self?.emitTrackingEnabledStatus()
                }
            }
            
            if ExposureManager.authorizationStatus == .authorized {
                self?.enManager.setExposureNotificationEnabled(LocalStore.shared.exposureNotificationsEnabled){ _ in }
            }
        }
    }
    
    /**
     Checks bluetooth state and emits onNext event to TrackingEnabledSubject.
     
     Emits onNext event to TrackingEnabledSubject, also saves last state to User Defaults.
     In case Bluetooth is off, onNext value will become false, however User Defaults will save prefered tracking state.
     If tracking disabled, reminder notification will be scheduled
     - Parameter enabled: optional new state. If nill. last known state will be emmited
     */
    private func emitTrackingEnabledStatus(enabled: Bool? = nil){
        
        if let enabled = enabled {
            LocalStore.shared.exposureNotificationsEnabled = enabled
        }
        
        let trackingEnabled = enabled ?? trackingIsWorking
        
        let trackingIsWorking = trackingEnabled && bluetoothEnabled && exposureNotificationEnabled ?? true
        
        TrackingIsWorkingSubject.onNext(trackingIsWorking)
        
        if trackingIsWorking {
            NotificationsScheduler.shared.clearDeliveredNotifications(for: .TrackingDisabled)
        }
        
        enableExposureStateReminder(LocalStore.shared.exposureStateReminderEnabled)
    }
    
    func enableExposureStateReminder(_ notificationsEnabled: Bool){
        do {
            LocalStore.shared.exposureStateReminderEnabled = notificationsEnabled
            let trackingIsWorking = try TrackingIsWorkingSubject.value()
            
            if !trackingIsWorking && notificationsEnabled {
                NotificationsScheduler.shared.schedule(.TrackingDisabled)
            } else {
                NotificationsScheduler.shared.removePendingNotifications(for: .TrackingDisabled)
            }
        } catch {
            justPrintError(error)
        }
    }
    
    func setExposureNotificationsEnabled(_ enabled: Bool) -> Completable {

        return Completable.create { (completable) -> Disposable in
            
            self.enManager.setExposureNotificationEnabled(enabled) { [weak self] error in
                guard let `self` = self else { return }
                
                if enabled && !self.bluetoothEnabled {
                    completable(.error(StateError.bluetoothDisabled))
                    return
                }
                
                if let error = error {
                    completable(.error(StateError.from(enError: error) ?? error))
                    return
                }
                
                self.emitTrackingEnabledStatus(enabled: enabled)
                completable(.completed)
            }
            
            return Disposables.create()
        }
    }
    
    /// EN Framework returns current day's TEK with test entitlements, that are only available in debug
    private func getDiagnosisKeys() -> Observable<[ENTemporaryExposureKey]> {
        var observable: Observable<[ENTemporaryExposureKey]>
        #if DEBUG
            observable = getTestDiagnosisKeys()
        #else
            observable = getReleaseDiagnosisKeys()
        #endif
        return observable
    }
    
    private func getReleaseDiagnosisKeys() -> Observable<[ENTemporaryExposureKey]> {
        return Observable.create { (observer) -> Disposable in
            self.enManager.getDiagnosisKeys { (keys, error) in
                if let err = error {
                    observer.onError(err)
                    return
                }
                
                observer.onNext(keys ?? [])
            }
            return Disposables.create()
        }
    }
    
    private func getTestDiagnosisKeys() -> Observable<[ENTemporaryExposureKey]> {
        return Observable.create { (observer) -> Disposable in
            self.enManager.getTestDiagnosisKeys { (keys, error) in
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
    
    private func detectExposures(localUrls: [URL], configuration: ENExposureConfiguration) -> Observable<ENExposureDetectionSummary?> {
        guard localUrls.count > 0 else {
            return Observable.just(nil)
        }
        
        return Observable.create { (observer) -> Disposable in
            let task = self.enManager.detectExposures(configuration: configuration, diagnosisKeyURLs: localUrls) { (summary, error) in
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
    
    private func getExposureInfo(summary: ENExposureDetectionSummary) -> Observable<[Exposure]> {
        return Observable.create { (observer) -> Disposable in
            let task = self.enManager.getExposureInfo(summary: summary, userExplanation: "exposure_detected_subtitle".translated) { (exposures, error) in
                guard error == nil else {
                    observer.onError(error!)
                    return
                }
                
                observer.onNext(exposures?.map{ Exposure(from: $0) } ?? [])
            }
            
            return Disposables.create {
                task.cancel()
            }
        }
    }
    
    /**
     Main exposure detection method
     
     Downloads new batches, gets exposure configuration from the remote server, runs local exposure check
     */
    func performExposureDetection() -> Observable<Bool> {
        return ExposuresClient.shared.downloadDiagnosisBatches(startAt: LocalStore.shared.lastDownloadedBatchIndex)
            .flatMap { (urls) -> Observable<[Exposure]> in
                return ExposuresClient.shared.getExposuresConfiguration()
                    .flatMap { (config) -> Observable<[Exposure]> in
                        guard let configuration = config else {
                            return Observable.error(NSError.make("Unable to fetch exposure configuration"))
                        }
                        return self.detectExposures(localUrls: urls.urls, configuration: configuration)
                            .flatMap { (summary) -> Observable<[Exposure]> in
                                guard let summary = summary else {
                                    return Observable.error(NSError.make("Returned empty summary from exposure detector"))
                                }
                                
                                guard summary.matchedKeyCount > 0 && summary.maximumRiskScore >= configuration.minimumRiskScore else {
                                    return Observable.just([])
                                }
                                
                                return self.getExposureInfo(summary: summary)
                            }
                            .do(onNext: { _ in
                                if let index = urls.lastIndex {
                                    LocalStore.shared.lastDownloadedBatchIndex = index
                                }
                            })
                }
            }
            .do(onNext: { [weak self] exposures in
                LocalStore.shared.exposures += exposures.map {
                    ExposureWrapper(uuid: UUID().uuidString, exposure: $0, uploadetAt: nil)
                }
                LocalStore.shared.cleanExpiredExposures()
                self?.reset()
            }, onError: { [weak self]  (error) in
                justPrintError(error)
                self?.reset()
                LocalStore.shared.cleanExpiredExposures()
            })
            .flatMap { (exposures) -> Observable<Bool> in
                return ExposuresClient.shared.uploadExposures()
        }
    }
}
