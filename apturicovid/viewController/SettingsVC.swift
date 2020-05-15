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
    
    @IBOutlet var languageButtons: [UIButton]! {
        didSet {
            languageButtons.forEach { button in
                button.layer.borderWidth = 2
                button.layer.borderColor = Colors.darkGreen.cgColor
                button.layer.cornerRadius = 5
                
                button.setTitleColor(Colors.darkGreen, for: .selected)
                button.setTitleColor(Colors.lightGreen, for: .normal)
                
                button.tintColor = UIColor.clear
            }
            
            let selectedTag = Language.primary.rawValue
//            let selectedButton = languageButtons.first { $0.tag == selectedTag } ?? languageButtons.first!
//            updateButtons(selectedButton)
        }
    }
    @IBOutlet weak var headerView: UIView! {
        didSet {
            headerView.roundCorners(corners: [.bottomRight, .bottomLeft], radius: 20)
            headerView.clipsToBounds = true
        }
    }
    @IBOutlet weak var titleLabel: UILabel!
    @IBAction func languageEn(_ sender: UIButton) {
        Language.primary = .EN
        updateButtons(sender)
    }
    @IBAction func languageLv(_ sender: UIButton) {
        Language.primary = .LV
        updateButtons(sender)
    }
    @IBAction func languageRu(_ sender: UIButton) {
        Language.primary = .RU
        updateButtons(sender)
    }
   
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
    
    private func setupPhoneViews() {
        guard let phoneNumber = LocalStore.shared.phoneNumber else {
            phoneView.isHidden = true
            return
        }
        
        setupPhoneView.isHidden = true
        phoneLabel.text = phoneNumber.number
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
    
    private func updateButtons(_ selectedButton: UIButton) {
        languageButtons.forEach {
            let selected = $0 == selectedButton
            $0.isSelected = selected
            $0.layer.borderColor = (selected ? Colors.darkGreen : UIColor.clear).cgColor
        }
    }
}
