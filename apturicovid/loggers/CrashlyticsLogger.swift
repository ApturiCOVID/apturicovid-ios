import Foundation
import CocoaLumberjack
import FirebaseCrashlytics

///
/// Taken from https://gist.github.com/xquezme/5a56ab58d7f593d3e5321f698fb7f30c
///

@objcMembers
final class CrashlyticsLogger: DDAbstractLogger {
    static let sharedInstance = CrashlyticsLogger()
    let crashlyticsInstance = Crashlytics.crashlytics()
    
    private func write(string: String) {
        crashlyticsInstance.log(format: "%@", arguments: getVaList([string]))
    }

    private override init() {
        super.init()
        self.logFormatter = DDLogFileFormatterDefault()
    }

    override func log(message logMessage: DDLogMessage) {
        guard let message = message(from: logMessage) else { return }

        write(string: message)
        if logMessage.flag == .error { record(error: logMessage) }
    }
        
    /// Records non-fatals from DDLogError
    private func record(error: DDLogMessage) {
        guard let message = message(from: error) else { return }
        
        let error = NSError(domain: error.message, code: 0, userInfo: [
            NSLocalizedFailureReasonErrorKey: message
        ])
        
        crashlyticsInstance.record(error: error)
    }
    
    private func message(from log: DDLogMessage) -> String? {
        guard
            let formatter = self.value(forKey: "_logFormatter") as? DDLogFormatter,
            let message = formatter.format(message: log)
        else { return nil }
        return message
    }
}
