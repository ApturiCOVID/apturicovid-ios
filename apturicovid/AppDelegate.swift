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
        
        UNUserNotificationCenter.current().delegate = self
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: AppDelegate.backgroundTaskIdentifier, using: .main) { (task) in
            _ = ExposureManager.shared.detectExposures()
                .subscribe(onNext: { (exposures) in
                    task.setTaskCompleted(success: true)
                    if exposures.count > 0 {
                        NoticationsScheduler.shared.sendExposureDiscoveredNotification()
                    }
                }, onError: { error in
                    justPrintError(error)
                    task.setTaskCompleted(success: false)
                })
            
            self.scheduleBackgroundTaskIfNeeded()
        }
        
        self.scheduleBackgroundTaskIfNeeded()
        
        NoticationsScheduler.shared.scheduleExposureCheckSilent()
        
        return true
    }
    
    func scheduleBackgroundTaskIfNeeded() {
        guard ENManager.authorizationStatus == .authorized else { return }
        let taskRequest = BGProcessingTaskRequest(identifier: AppDelegate.backgroundTaskIdentifier)
        taskRequest.earliestBeginDate = nil
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
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if notification.request.identifier == "SilentPush" {
            _ = ExposureManager.shared.detectExposures()
                .subscribe(onNext: { (_) in
                    completionHandler([])
                }, onError: justPrintError)
        } else {
            completionHandler([.alert, .sound])
        }
    }
}
