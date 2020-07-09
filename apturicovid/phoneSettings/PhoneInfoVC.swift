import UIKit

class PhoneInfoVC: BaseViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var privacyProtectionLabel: UILabel!
    @IBOutlet weak var closeButton: RoundedButton!
    @IBOutlet weak var backButton: RoundedButton!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var statusBarBlurView: UIVisualEffectView!
    @IBOutlet weak var fadeView: FadeView!
    
    @IBAction func onBackTap(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    override func translate() {
        titleLabel.text = "why_submit_a_phone_number".translated
        descriptionLabel.text = "why_submit_a_phone_number_explanation".translated
        privacyProtectionLabel.text = "data_privacy_and_protection_policy".translated
        closeButton.setText("close".translated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        scrollView.flashScrollIndicators()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.delegate = self
        scrollView.adjustContentInset(for: fadeView)
    }
}

extension PhoneInfoVC : UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {

        let offset = scrollView.contentOffset.y + scrollView.contentInset.top
        statusBarBlurView.effect = offset > -view.safeAreaInsets.top ? UIBlurEffect(style: .light) : nil
        
        backButton.updateShadowOpacity(fromContentOffset: scrollView.contentOffset,
                                       shadowApplyBeginOffset: 0,
                                       shadowApplyIntensity: 800,
                                       shadowMaxOpasity: 0.3)
    }
    
}
