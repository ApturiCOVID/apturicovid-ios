import Foundation
import NotificationCenter
import CocoaLumberjack

class NotificationsScheduler {
    static let shared = NotificationsScheduler()
    
    let notificationCenter: UNUserNotificationCenter
    
    init() {
        notificationCenter = UNUserNotificationCenter.current()
        
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        notificationCenter.requestAuthorization(options: options) { (allowed, error) in
            if let error = error { justPrintError(error) }
        }
    }
    
    func scheduleExposureStateNotification() {
        guard !LocalStore.shared.exposureNotificationsEnabled && LocalStore.shared.exposureStateReminderEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "exposure_disabled_notification_title".translated
        content.body = "exposure_disabled_notification_description".translated
        content.sound = UNNotificationSound.default
        
        var dateComponents = DateComponents()
        dateComponents.calendar = Calendar.current
        dateComponents.hour = 10
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "ExposureStateNotification", content: content, trigger: trigger)
        
        notificationCenter.add(request) { (error) in
            if let error = error {
                justPrintError(error)
                return
            }
            DDLogInfo("Exposure State Notification scheduled")
        }
    }
    
    func removeExposureStateReminder() {
        notificationCenter.removeAllPendingNotificationRequests()
        DDLogInfo("Pending notification requests removed")
    }
    
    func sendExposureDiscoveredNotification() {
        let content = UNMutableNotificationContent()
        content.title = "exposure_detected_notification_title".translated
        content.body = "exposure_detected_notification_description".translated
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
        let request = UNNotificationRequest(identifier: "ExposureNotification", content: content, trigger: trigger)
        
        notificationCenter.add(request) { (error) in
            if let error = error {
                justPrintError(error)
                return
            }
            DDLogInfo("Scheduled exposure notification")
        }
    }
    
    class func registerBackgroundTask() -> UIBackgroundTaskIdentifier{
      var backgroundTask :UIBackgroundTaskIdentifier!
      backgroundTask = UIApplication.shared.beginBackgroundTask {
        NotificationsScheduler.endBackgroundTask(&backgroundTask)
      }
      assert(backgroundTask != .invalid)
      return backgroundTask
    }

    class func endBackgroundTask(_ backgroundTask: inout UIBackgroundTaskIdentifier) {
      UIApplication.shared.endBackgroundTask(backgroundTask)
      let log = "End background task \(backgroundTask)"
      backgroundTask = .invalid
      DDLogInfo(log)
    }
}
