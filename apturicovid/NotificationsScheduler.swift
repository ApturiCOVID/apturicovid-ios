import Foundation
import NotificationCenter
import CocoaLumberjack

class NotificationsScheduler {
    static let shared = NotificationsScheduler()
    static let authorizationOptions: UNAuthorizationOptions = [.alert, .sound, .badge]
    
    let notificationCenter = UNUserNotificationCenter.current()
    
    private init(){}
    
    /// Schedules tracking disabled notification if not already scheduled.
    func schedule(_ notification: ExposureNotification) {
        
        getDeliveredNotifications(for: notification) { [weak self] deliveredNotifications in
            
            self?.removePendingNotifications(for: notification)
            
            guard deliveredNotifications.isEmpty else { return }
            
            Self.requestAuthorization { (granted, error) in
                guard granted else { return }
                
                self?.notificationCenter.add(notification.request) { (error) in
                    if let error = error {
                        justPrintError(error)
                    } else {
                        DDLogInfo("Exposure State Notification scheduled")
                    }
                }
            }
        }
    }
    
    func translatePendingNotifications(for notification: ExposureNotification){
        notificationCenter.getPendingNotificationRequests { [weak self] pendingNotifications in
            let matchingNotificationCount = pendingNotifications.filter{ $0.identifier == notification.identifier}.count
            guard matchingNotificationCount > 0 else { return }
            
            self?.removePendingNotifications(for: notification)
            for _ in 0..<matchingNotificationCount { self?.schedule(notification) }
        }
    }
    
    /// Removes pending notifications of specified type
    func removePendingNotifications(for notification: ExposureNotification){
        notificationCenter.getPendingNotificationRequests { [weak self] pendingNotifications in
            if pendingNotifications.contains(where: { $0.identifier == notification.identifier }){
                self?.notificationCenter.removePendingNotificationRequests(withIdentifiers: [notification.identifier])
                DDLogInfo("Pending \(notification.identifier) notifications removed")
            }
        }
    }
    
    /// Returns delivered notifications of specified type
    func getDeliveredNotifications(for notification: ExposureNotification, completionHandler: @escaping ([UNNotification]) -> Void ) {
        notificationCenter.getDeliveredNotifications { notifications in
            let stateNotifications = notifications.filter { $0.request.identifier == notification.identifier }
            completionHandler(stateNotifications)
        }
    }
    
    /// Clears delivered notifications of specified type
    func clearDeliveredNotifications(for notification: ExposureNotification){
        getDeliveredNotifications(for: notification){ [weak self] delivered in
            if !delivered.isEmpty {
                self?.notificationCenter.removeDeliveredNotifications(withIdentifiers: [notification.identifier])
                DDLogInfo("Delivered \(notification.identifier) notifications removed")
            }
        }
    }
    
    class func checkAuthorizationStatus(completionHandler: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter
            .current()
            .getNotificationSettings(){ completionHandler($0.authorizationStatus) }
    }
    
    class func requestAuthorization(options: UNAuthorizationOptions = authorizationOptions,
                                    completionHandler: @escaping (Bool, Error?) -> Void) {
        UNUserNotificationCenter
            .current()
            .requestAuthorization(options: options,completionHandler: completionHandler)
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

extension NotificationsScheduler {
    
    enum ExposureNotification: String, CaseIterable {
        
        case TrackingDisabled, ExposureDiscovered
        
        var identifier: String { rawValue }
        
        var title: String {
            switch self {
            case .TrackingDisabled:
                return "exposure_disabled_notification_title".translated
            case .ExposureDiscovered:
                return "exposure_detected_notification_title".translated
            }
        }
        
        var body: String {
            switch self {
            case .TrackingDisabled:
                return "exposure_disabled_notification_description".translated
            case .ExposureDiscovered:
                return "exposure_detected_notification_description".translated
            }
        }
        
        var sound: UNNotificationSound {
            .default
        }
        
        var trigger: UNNotificationTrigger {
            switch self {
            case .TrackingDisabled:
                var dateComponents = DateComponents()
                dateComponents.calendar = .current
                dateComponents.hour = 10
                return UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            case .ExposureDiscovered:
                return UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
            }
        }
        
        var content: UNMutableNotificationContent {
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = sound
            return content
        }
        
        var request: UNNotificationRequest {
            UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        }
    }

}
