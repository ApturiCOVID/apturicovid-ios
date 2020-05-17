import UIKit
import CocoaLumberjack

class BackgroundManager {
    static let shared = BackgroundManager()
    
    func scheduleExposureUploadTask() {
        var task = scheduleTask()
        RestClient.shared.uploadExposures { (result) in
            switch result {
            case let .failure(error):
                DDLogError(error.localizedDescription)
            default: break
            }
            self.invalidateTask(&task)
        }
    }
    
    private func scheduleTask() -> UIBackgroundTaskIdentifier {
        var task: UIBackgroundTaskIdentifier!
        task = UIApplication.shared.beginBackgroundTask {
            self.invalidateTask(&task)
        }
        assert(task != .invalid)
        return task
    }
    
    func invalidateTask(_ task: inout UIBackgroundTaskIdentifier) {
        DDLogInfo("invalidating task \(task)")
        UIApplication.shared.endBackgroundTask(task)
        task = .invalid
    }
}
