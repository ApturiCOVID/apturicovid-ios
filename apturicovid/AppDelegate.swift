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
            print(task)
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
        
        scheduleBackgroundTaskIfNeeded()
        
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        self.scheduleBackgroundTaskIfNeeded()
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let storyboard: Storyboard = .Main
        return storyboard.sceneConfiguration(for: connectingSceneSession)

    }
    
    func scheduleBackgroundTaskIfNeeded() {
        guard ENManager.authorizationStatus == .authorized else { return }
        let taskRequest = BGProcessingTaskRequest(identifier: AppDelegate.backgroundTaskIdentifier)
        taskRequest.earliestBeginDate = nil
        taskRequest.requiresNetworkConnectivity = true
        do {
            try BGTaskScheduler.shared.submit(taskRequest)
            print("did schedule task")
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
        completionHandler([.alert, .sound])
    }
}

//MARK: - Storyboard
enum Storyboard: String {
    case Main, Welcome
    
    var instance: UIStoryboard {
        UIStoryboard(name: self.rawValue, bundle: Bundle.main)
    }
    
    func sceneConfiguration(for session: UISceneSession) -> UISceneConfiguration {
        UISceneConfiguration(name: self.rawValue, sessionRole: session.role)
    }
}
