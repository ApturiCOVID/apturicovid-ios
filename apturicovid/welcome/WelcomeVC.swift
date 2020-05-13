import UIKit

class WelcomeVC: UIViewController {
    
    @IBOutlet weak var acceptancesStack: UIStackView!
    @IBOutlet weak var langaugesStack: UIStackView!
    @IBOutlet weak var headingLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var nextButton: RoundedButton!
    
    @IBAction func nextTap(_ sender: Any) {
        
    }
    
    let privacyAndTermsCheckboxView = CheckboxView().fromNib()
    let langViews = Language.allCases.map{ LanguageView.create($0) }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        acceptancesStack.addArrangedSubview(privacyAndTermsCheckboxView!)
        setupLanguageSelector()
        nextButton.isEnabled = false
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
}
