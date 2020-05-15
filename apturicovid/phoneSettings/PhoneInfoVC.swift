import UIKit

class PhoneInfoVC: UIViewController {
    @IBAction func onBackTap(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}
