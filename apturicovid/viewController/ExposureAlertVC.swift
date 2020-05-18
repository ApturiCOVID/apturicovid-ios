import UIKit

class ExposureAlertVC: BaseViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var exposedLabel: UILabel!
    @IBOutlet weak var howToProceedLabel: UILabel!
    @IBOutlet weak var selfIsolateLabel: UILabel!
    @IBOutlet weak var spkcCallLabel: UILabel!
    @IBOutlet weak var familyDoctorLabel: UILabel!
    @IBOutlet weak var symptomsLabel: UILabel!
    @IBOutlet weak var handlingDescription: UILabel!
    @IBOutlet weak var continueButton: RoundedButton!
    
    @IBAction func onContinueTap(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func translate() {
        let isPhoneSpecified = !(LocalStore.shared.phoneNumber?.number.isEmpty ?? true)
        
        titleLabel.text = "exposure_with_covid".translated
        exposedLabel.text = "you_had_exposure".translated
        howToProceedLabel.text = "how_to_proceed".translated
        selfIsolateLabel.text = "self_isolate".translated
        spkcCallLabel.text = "wait_for_a_call_from_spkc".translated
        familyDoctorLabel.text = "contact_your_family_doctor".translated
        symptomsLabel.text = "observe_symptoms".translated
        handlingDescription.text =  isPhoneSpecified ? "exposure_handling_description_phone_specified".translated : "exposure_handling_description_phone_not_specified".translated
        continueButton.setTitle("continue".translated, for: .normal)
    }
}
