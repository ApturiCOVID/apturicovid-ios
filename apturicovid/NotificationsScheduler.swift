import Foundation
import NotificationCenter

class NoticationsScheduler {
    static let shared = NoticationsScheduler()
    
    let notificationCenter: UNUserNotificationCenter
    
    init() {
        notificationCenter = UNUserNotificationCenter.current()
        
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        notificationCenter.requestAuthorization(options: options) { (allowed, error) in
            print(allowed)
            print(error)
        }
    }
    
    func scheduleExposureStateNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Es nesapratu?"
        content.body = "Kurš tad ieslēgs covid exposure paziņojumus?"
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: true)
        let request = UNNotificationRequest(identifier: "ExposureStateNotification", content: content, trigger: trigger)
        
        notificationCenter.add(request) { (error) in
            print(error)
        }
    }
    
    func removeExposureStateReminder() {
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    func sendExposureDiscoveredNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Oupsie! You've been exposed"
        content.body = "Ko darīt! Ar katru gadās!"
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 20, repeats: false)
        let request = UNNotificationRequest(identifier: "ExposureNotification", content: content, trigger: trigger)
        
        notificationCenter.add(request) { (err) in
            print(err)
        }
    }
}
