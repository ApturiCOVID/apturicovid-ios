import UIKit

class PhoneInfoVC: BaseViewController {
    @IBAction func onBackTap(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}
