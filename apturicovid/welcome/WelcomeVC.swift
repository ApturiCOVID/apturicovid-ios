import UIKit
import RxSwift
import RxCocoa

class WelcomeVC: BaseViewController {
    
    @IBOutlet weak var acceptancesStack: UIStackView!
    @IBOutlet weak var langaugesStack: UIStackView!
    @IBOutlet weak var headingLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var nextButton: RoundedButton!
    
    @IBAction func nextTap(_ sender: Any) {
        
    }
    
    let privacyAndTermsCheckboxView = CheckboxView.create(text: "", isChecked: false)
    let langViews = Language.allCases.map{ LanguageView.create($0) }
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLanguageSelector()
        setupPrivacyAndTermsCheckBox()
    }
    
    private func setupLanguageSelector(){
        langViews.forEach { langView in
            
            langView.translatesAutoresizingMaskIntoConstraints = false
            langView.widthAnchor.constraint(equalToConstant: 50).isActive = true
            langView.heightAnchor.constraint(equalToConstant: 50).isActive = true
            
            langaugesStack.addArrangedSubview(langView)
           
            langView.onSelected(){ [weak self] selected in
                guard selected else { return }
                Language.primary = langView.language
                self?.langViews
                    .filter{ $0.language != langView.language }
                    .forEach{ $0.isSelected = false }
            }
        }
    }
    
    private func setupPrivacyAndTermsCheckBox(){
        nextButton.isEnabled = false
        acceptancesStack.addArrangedSubview(privacyAndTermsCheckboxView)
        
        // Enable next button when terms accepted
        privacyAndTermsCheckboxView.checkBox.rx.tap
            .map { self.privacyAndTermsCheckboxView.isChecked }
            .bind(to: nextButton.rx.isEnabled)
            .disposed(by: disposeBag)
    }
    
    override func translate() {
        headingLabel.text = "welcome_title".translated
        bodyLabel.text = "welcome_app_description".translated
        privacyAndTermsCheckboxView.text = "welcome_privacy_note".translated
        nextButton.setTitle("welcome_continue".translated, for: .normal)
    }
}
