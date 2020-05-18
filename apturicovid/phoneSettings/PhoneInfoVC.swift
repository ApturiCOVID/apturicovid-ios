import UIKit

class PhoneInfoVC: BaseViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var privacyProtectionLabel: UILabel!
    @IBOutlet weak var closeButton: RoundedButton!
    
    @IBAction func onBackTap(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    override func translate() {
        titleLabel.text = "why_submit_a_phone_number".translated
        descriptionLabel.text = "why_submit_a_phone_number_explanation".translated
        privacyProtectionLabel.text = "data_privacy_and_protection_policy".translated
        closeButton.setTitle("close".translated, for: .normal)
    }
}
