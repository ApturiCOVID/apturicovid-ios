import UIKit

class ExposureAlertVC: BaseViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var exposedLabel: UILabel!
    @IBOutlet weak var howToProceedLabel: UILabel!
    @IBOutlet weak var selfIsolateLabel: UILabel!
    @IBOutlet weak var spkcCallLabel: UILabel!
    @IBOutlet weak var familyDoctorLabel: UILabel!
    @IBOutlet weak var symptomsLabel: UILabel!
    @IBOutlet weak var waitSPKCCallLabel: UILabel!
    @IBOutlet weak var handlingDescription: UILabel!
    @IBOutlet weak var phoneInputButton: RoundedButton!
    @IBOutlet weak var phoneButtonContainerHeight: NSLayoutConstraint!
    
    @IBOutlet weak var statusBarBlurView: UIVisualEffectView!
    @IBOutlet weak var backButton: RoundedButton!
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBAction func onPhoneInputTap(_ sender: Any) {
        if let vc = UIStoryboard(name: "PhoneSettings", bundle: nil).instantiateInitialViewController() {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    @IBAction func onBackTap(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    override func translate() {
        let isPhoneSpecified = !(LocalStore.shared.phoneNumber?.number.isEmpty ?? true)
        
        titleLabel.text = "exposure_with_covid".translated
        exposedLabel.text = "you_had_exposure".translated
        howToProceedLabel.text = "how_to_proceed".translated
        
        selfIsolateLabel.text = "self_isolate".translated
        symptomsLabel.text = "observe_symptoms".translated
        familyDoctorLabel.text = "contact_your_family_doctor".translated
        
        spkcCallLabel.text = "severe_case".translated
        waitSPKCCallLabel.text = "wait_for_a_call_from_spkc".translated
        
        handlingDescription.text =  isPhoneSpecified ? "exposure_handling_description_phone_specified".translated : "exposure_handling_description_phone_not_specified".translated
        
        
        phoneInputButton.setTitle("specify".translated, for: .normal)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        if LocalStore.shared.phoneNumber != nil {
            phoneButtonContainerHeight.constant = 0
            phoneInputButton.isHidden = true
        }
        scrollView.delegate = self
    }
}

extension ExposureAlertVC : UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {

        let offset = scrollView.contentOffset.y + scrollView.contentInset.top
        statusBarBlurView.effect = offset > -view.safeAreaInsets.top ? UIBlurEffect(style: .light) : nil
        
        backButton.updateShadowOpacity(fromContentOffset: scrollView.contentOffset,
                                       shadowApplyBeginOffset: 0,
                                       shadowApplyIntensity: 800,
                                       shadowMaxOpasity: 0.3)
    }
    
}
