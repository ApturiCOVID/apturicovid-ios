import UIKit
import Foundation
import RxSwift
import RxCocoa

class SettingsViewController: BaseViewController {
    private let languageToTagMap = [
        "lv": 0,
        "en": 1,
        "ru": 2
    ]
    
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
            
            let selectedTag = languageToTagMap[language]
            let selectedButton = languageButtons.first { $0.tag == selectedTag } ?? languageButtons.first!
            updateButtons(selectedButton)
        }
    }
    @IBOutlet weak var headerView: UIView! {
        didSet {
            headerView.layer.cornerRadius = 22
            headerView.clipsToBounds = true
        }
    }
    @IBOutlet weak var titleLabel: UILabel!
    @IBAction func languageEn(_ sender: UIButton) {
        language = "en"
        
        updateButtons(sender)
    }
    @IBAction func languageLv(_ sender: UIButton) {
        language = "lv"
        
        updateButtons(sender)
    }
    @IBAction func languageRu(_ sender: UIButton) {
        language = "ru"
        
        updateButtons(sender)
    }
    
    @IBOutlet weak var submitButton: UIButton! {
        didSet {
            submitButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
            submitButton.layer.cornerRadius = 22
            submitButton.clipsToBounds = true
        }
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
