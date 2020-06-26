import UIKit

class DebugActionsVC: UIViewController {
    @IBAction func onAllDataDeleteTap(_ sender: Any) {
        LocalStore.shared.lastDownloadedBatchIndex = 0
        LocalStore.shared.exposures = []
    }
    @IBAction func onDeleteExposuresTap(_ sender: Any) {
        LocalStore.shared.exposures = []
    }
    
    @IBAction func onIndexDeleteTap(_ sender: Any) {
        LocalStore.shared.lastDownloadedBatchIndex = 0
    }
    
}
