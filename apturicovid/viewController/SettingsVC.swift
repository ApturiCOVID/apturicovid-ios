import UIKit
import Foundation
import RxSwift
import RxCocoa

class SettingsViewController: BaseViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var spkcCodeDescriptionLabel: UILabel!
    @IBOutlet weak var submitButton: RoundedButton!
    @IBOutlet weak var communicationContactLabel: UILabel!    
    @IBOutlet weak var changeButton: UIButton!
    @IBOutlet weak var notSpecifiedLabel: UILabel!
    @IBOutlet weak var specifyButton: UIButton!
    @IBOutlet weak var contactDescriptionLabel: UILabel!
    @IBOutlet weak var notifyMeLabel: UILabel!
    @IBOutlet weak var deleteDataLabel: UILabel!
    @IBOutlet weak var mainStackView: UIStackView!
    @IBOutlet weak var phoneView: UIView!
    @IBOutlet weak var setupPhoneView: UIView!
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var reminderSwitch: UISwitch!
    @IBOutlet weak var languagesStack: UIStackView!
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var deleteDataView: UIView!

    let langViews = Language.allCases.map{ LanguageView.create($0) }
    
    @IBAction func onReminderSet(_ sender: UISwitch) {
        LocalStore.shared.exposureStateReminderEnabled = sender.isOn
        if sender.isOn {
            NotificationsScheduler.shared.scheduleExposureStateNotification()
        } else {
            NotificationsScheduler.shared.removeExposureStateReminder()
        }
    }
    
    @IBAction func changePhone(_ sender: Any) {
        guard let vc = UIStoryboard(name: "PhoneSettings", bundle: nil).instantiateInitialViewController() else { return }
        navigationController?.pushViewController(vc, animated: true)
    }
   
    @IBAction func onSubmitPress(_ sender: Any) {
        guard let vc = UIStoryboard(name: "CodeEntry", bundle: nil).instantiateInitialViewController() as? CodeEntryVC else { return }
        
        vc.mode = .spkc
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func setupLanguageSelector(){
        langViews.forEach { langView in
            
            languagesStack.addArrangedSubview(langView)
            
            langView.translatesAutoresizingMaskIntoConstraints = false
            langView.widthAnchor.constraint(equalTo:languagesStack.heightAnchor).isActive = true
            langView.heightAnchor.constraint(equalTo:languagesStack.heightAnchor).isActive = true
           
            langView.onSelected(){ [weak self] selected in
                guard selected else { return }
                Language.primary = langView.language
                self?.langViews
                    .filter{ $0.language != langView.language }
                    .forEach{ $0.isSelected = false }
            }
        }
    }
    
    private func setupPhoneViews() {
        let phoneNumberAbsent = LocalStore.shared.phoneNumber == nil
        
        phoneView.isHidden = phoneNumberAbsent
        setupPhoneView.isHidden = !phoneNumberAbsent
        phoneLabel.text = LocalStore.shared.phoneNumber?.number
    }
    
    private func deleteData() {
        LocalStore.shared.exposures = []
        LocalStore.shared.lastDownloadedBatchIndex = 0
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLanguageSelector()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupPhoneViews()
        
        reminderSwitch.isOn = LocalStore.shared.exposureStateReminderEnabled
        
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String, let bundleV = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
               versionLabel.text = "Versijas nr.: \(version) (\(bundleV))"
           }
        
        deleteDataView.rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { _ in
                self.deleteData()
            })
            .disposed(by: disposeBag)
    }
    
    override func translate() {
        titleLabel.text = "settings".translated
        spkcCodeDescriptionLabel.text = "enter_spkc_code".translated
        submitButton.setTitle("go_to_spkc_code_entry".translated, for: .normal)
        communicationContactLabel.text = "communication_contact".translated
        notSpecifiedLabel.text = "not_specified".translated
        specifyButton.setTitle("specify".translated, for: .normal)
        changeButton.setTitle("change".translated, for: .normal)
        contactDescriptionLabel.text = "not_specified_phone_number_limitations".translated
        notifyMeLabel.text = "notify_if_tracking_isnt_working".translated
        deleteDataLabel.text = "delete_all_stored_data".translated
        submitButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        submitButton.sizeToFit()
    }
}
