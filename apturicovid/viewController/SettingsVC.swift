import UIKit
import Foundation
import RxSwift
import RxCocoa

class SettingsViewController: BaseViewController {
    
    @IBOutlet weak var statusBarBlurView: UIVisualEffectView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var spkcCodeDescriptionLabel: UILabel!
    @IBOutlet weak var submitButton: RoundedButton!
    @IBOutlet weak var communicationContactLabel: UILabel!    
    @IBOutlet weak var changeButton: UIButton!
    @IBOutlet weak var notSpecifiedLabel: UILabel!
    @IBOutlet weak var specifyButton: UIButton!
    @IBOutlet weak var contactDescriptionLabel: UILabel!
    @IBOutlet weak var notifyMeLabel: UILabel!
    @IBOutlet weak var mainStackView: UIStackView!
    @IBOutlet weak var phoneView: UIView!
    @IBOutlet weak var setupPhoneView: UIView!
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var reminderSwitch: UISwitch!
    @IBOutlet weak var languagesStack: UIStackView!
    @IBOutlet weak var versionLabel: UILabel!

    let langViews = Language.allCases.map{ LanguageView.create($0) }
    
    @IBAction func onReminderSet(_ sender: UISwitch) {
        enableNotifications(sender.isOn, referenceSwitch: sender, animated: true)
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
            
            langView.isSelected = langView.language.isPrimary
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
        
        NotificationCenter.default.rx
        .notification(UIApplication.didBecomeActiveNotification)
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: { [weak self] (_) in
            self?.updateReminderSwitchStatus()
        }, onError: justPrintError)
        .disposed(by: disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupPhoneViews()
        updateReminderSwitchStatus()
        
        scrollView.delegate = self
        
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String, let bundleV = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
               versionLabel.text = "v \(version) (\(bundleV))"
           }
    }
    
    func updateReminderSwitchStatus(){
        reminderSwitch.isOn = LocalStore.shared.exposureStateReminderEnabled
        
        if reminderSwitch.isOn {
            NotificationsScheduler.checkAuthorizationStatus { [weak self] (status) in
                if status != .authorized {
                    self?.enableNotifications(false, referenceSwitch: self?.reminderSwitch, animated: false)
                }
            }
        }
    }
    
    override func translate() {
        self.tabBarItem.title = "settings".translated
        titleLabel.text = "settings".translated
        spkcCodeDescriptionLabel.text = "enter_spkc_code".translated
        submitButton.setTitle("go_to_spkc_code_entry".translated, for: .normal)
        communicationContactLabel.text = "communication_contact".translated
        notSpecifiedLabel.text = "not_specified".translated
        specifyButton.setTitle("specify".translated, for: .normal)
        changeButton.setTitle("change".translated, for: .normal)
        contactDescriptionLabel.text = "not_specified_phone_number_limitations".translated
        notifyMeLabel.text = "notify_if_tracking_isnt_working".translated
        submitButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        submitButton.sizeToFit()
    }
    
    private func enableNotifications(_ enable: Bool, referenceSwitch: UISwitch? , animated: Bool = true){
        
        func setOff(animated: Bool = animated){
            DispatchQueue.main.async {
                ExposureManager.shared.enableExposureStateReminder(false)
                referenceSwitch?.setOn(false, animated: animated)
            }
        }
        
        func authorize(goToSettingsIfUnauthorized: Bool){
            NotificationsScheduler.requestAuthorization { [weak self] (allowed, error) in
                DispatchQueue.main.async {
                    if allowed {
                        ExposureManager.shared.enableExposureStateReminder(enable)
                    } else {
                        if goToSettingsIfUnauthorized {
                            let alert = UIAlertController(title: "notifications_off_error".translated,
                                                          message: "notifications_usage_description".translated,
                                                          preferredStyle: .alert)
                            
                            alert.overrideUserInterfaceStyle = .light
                            
                            alert.addAction( UIAlertAction(title: "app_settings".translated,
                                                           style: .default) { _ in
                                                            ExposureManager.shared.enableExposureStateReminder(enable)
                                                            UIApplication.openSettings()
                            })
                            
                            alert.addAction( UIAlertAction(title: "close".translated,
                                                           style: .cancel){ _ in
                                                            setOff(animated: true)
                            })

                            self?.present(alert, animated: true)
                        } else {
                            setOff(animated: true)
                        }
                    }
                }
            }
        }
        
        guard enable else {
            setOff(animated: true)
            return
        }
        
        NotificationsScheduler.checkAuthorizationStatus { (status) in
            
            switch status {
            case .notDetermined:
                authorize(goToSettingsIfUnauthorized: false)
            default:
                authorize(goToSettingsIfUnauthorized: true)
            }
        }
    }
}

extension SettingsViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.y + scrollView.contentInset.top
        statusBarBlurView.effect = offset > -view.safeAreaInsets.top ? UIBlurEffect(style: .light) : nil
        
    }
    
}
