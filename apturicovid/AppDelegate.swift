import UIKit
import Firebase
import CocoaLumberjack
import ExposureNotification
import BackgroundTasks

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    static let backgroundTaskIdentifier = Bundle.main.bundleIdentifier! + ".exposure-notification"
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        DDLog.add(DDOSLogger.sharedInstance)
        DDLog.add(CrashlyticsLogger.sharedInstance)
        
        setAppearance()
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: AppDelegate.backgroundTaskIdentifier, using: .main) { task in
            
            let progress = ExposureManager.shared.backgroundDetection { success in
                task.setTaskCompleted(success: success)
            }
            
            task.expirationHandler = {
                progress.cancel()
                LocalStore.shared.exposureDetectionErrorLocalizedDescription = NSLocalizedString("BACKGROUND_TIMEOUT", comment: "Error")
            }
            
            self.scheduleBackgroundTaskIfNeeded()
        }
        
        self.scheduleBackgroundTaskIfNeeded()
        
        UIApplication.shared.registerForRemoteNotifications()
        
        Messaging.messaging().subscribe(toTopic: "exposure-refresh") { error in
            if let error = error {
                justPrintError(error)
                return
            }
            DDLogInfo("Subscribed to exposure-refresh topic")
        }
        
        return true
    }
    
    func scheduleBackgroundTaskIfNeeded() {
        guard ENManager.authorizationStatus == .authorized else { return }
        let taskRequest = BGProcessingTaskRequest(identifier: AppDelegate.backgroundTaskIdentifier)
        taskRequest.requiresNetworkConnectivity = true
        do {
            try BGTaskScheduler.shared.submit(taskRequest)
        } catch {
            print("Unable to schedule background task: \(error)")
        }
    }
    
    // MARK: Private
    
    func setAppearance() {
        UITabBar.appearance().tintColor = Colors.orange
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        ExposureManager.shared.refresh()
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        var task = NoticationsScheduler.registerBackgroundTask()
        _ = ExposureManager.shared.backgroundDetection { (success) in
            RestClient.shared.uploadExposures { (_) in
                ExposureManager.reset()
                NoticationsScheduler.endBackgroundTask(&task)
            }
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print(deviceToken.hexString)
    }
}
