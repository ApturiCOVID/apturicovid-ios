import UIKit
import Firebase
import CocoaLumberjack
import ExposureNotification
import BackgroundTasks
import RxSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    static let backgroundTaskIdentifier = "lv.spkc.gov.apturicovid.exposure-notification"
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        LocalStore.shared.clearPrivateDataOnFirstLaunch()
        
        window?.tintColor = Colors.globalTintColor
        
        Reachability.shared?.begin()
        FirebaseApp.configure()
        DDLog.add(DDOSLogger.sharedInstance)
        DDLog.add(CrashlyticsLogger.sharedInstance)
        
        setAppearance()
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: AppDelegate.backgroundTaskIdentifier, using: .main) { task in
            let disposable = ExposureManager.shared.performExposureDetection()
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { _ in
                    task.setTaskCompleted(success: true)
                }, onError: { (error) in
                    task.setTaskCompleted(success: false)
                    justPrintError(error)
                })
            
            task.expirationHandler = {
                disposable.dispose()
                LocalStore.shared.exposureDetectionErrorLocalizedDescription = NSLocalizedString("BACKGROUND_TIMEOUT", comment: "Error")
            }
            
            self.scheduleBackgroundTaskIfNeeded()
        }
        
        self.scheduleBackgroundTaskIfNeeded()
        return true
    }
    
    func scheduleBackgroundTaskIfNeeded() {
        guard ENManager.authorizationStatus == .authorized else { return }
        let taskRequest = BGProcessingTaskRequest(identifier: AppDelegate.backgroundTaskIdentifier)
        taskRequest.requiresNetworkConnectivity = true
        do {
            try BGTaskScheduler.shared.submit(taskRequest)
        } catch {
            DDLogError("Unable to schedule background task: \(error)")
        }
    }
    
    // MARK: Private
    
    func setAppearance() {
        UITabBar.appearance().tintColor = Colors.orange
    }
}
