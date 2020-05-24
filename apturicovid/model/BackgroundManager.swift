import UIKit
import CocoaLumberjack
import RxSwift

class BackgroundManager {
    static let shared = BackgroundManager()
    
    let disposeBag = DisposeBag()
    
    func scheduleExposureUploadTask() {
        ExposuresClient.shared.uploadExposures()
            .subscribe(onError: justPrintError)
            .disposed(by: disposeBag)
    }
}
