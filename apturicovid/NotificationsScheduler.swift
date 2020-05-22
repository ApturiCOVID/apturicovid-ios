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
        content.title = "Ieslēdz Exposure notifications"
        content.body = "Šis ir atgādinājums par to, ka jāieslēdz exposure notifications"
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
}
