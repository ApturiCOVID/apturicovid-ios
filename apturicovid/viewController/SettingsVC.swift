import UIKit
import Foundation
import RxSwift
import RxCocoa

class SettingsViewController: BaseViewController {
    private let languagees = Language.allCases
    @IBOutlet weak var mainStackView: UIStackView!
    @IBOutlet weak var phoneView: UIView!
    @IBOutlet weak var setupPhoneView: UIView!
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var reminderSwitch: UISwitch!
    @IBOutlet weak var languagesStack: UIStackView!
    
    let langViews = Language.allCases.map{ LanguageView.create($0) }
    
    @IBAction func onReminderSet(_ sender: UISwitch) {
        LocalStore.shared.exposureStateReminderEnabled = sender.isOn
        if sender.isOn {
            NoticationsScheduler.shared.scheduleExposureStateNotification()
        } else {
            NoticationsScheduler.shared.removeExposureStateReminder()
        }
    }
    
    @IBAction func changePhone(_ sender: Any) {
        guard let vc = UIStoryboard(name: "PhoneSettings", bundle: nil).instantiateInitialViewController() else { return }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBOutlet weak var headerView: UIView! {
        didSet {
            headerView.roundCorners(corners: [.bottomRight, .bottomLeft], radius: 20)
            headerView.clipsToBounds = true
        }
    }
    @IBOutlet weak var titleLabel: UILabel!
   
    @IBAction func onSubmitPress(_ sender: Any) {
        guard let vc = UIStoryboard(name: "CodeEntry", bundle: nil).instantiateInitialViewController() as? CodeEntryVC else { return }
        
        vc.mode = .spkc
        self.present(vc, animated: true, completion: nil)
    }
    
    @IBOutlet weak var submitButton: UIButton! {
        didSet {
            submitButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
            submitButton.layer.cornerRadius = 22
            submitButton.clipsToBounds = true
        }
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
        guard let phoneNumber = LocalStore.shared.phoneNumber else {
            phoneView.isHidden = true
            return
        }
        
        setupPhoneView.isHidden = true
        phoneLabel.text = phoneNumber.number
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLanguageSelector()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupPhoneViews()
        reminderSwitch.isOn = LocalStore.shared.exposureNotificationsEnabled
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    override func translate() {
        titleLabel.text = "settings_title".translated
        submitButton.setTitle("settings_enter_code".translated, for: .normal)
        
        submitButton.sizeToFit()
    }
}
