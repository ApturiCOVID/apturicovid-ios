import UIKit

class WelcomeVC: UIViewController {
    @IBOutlet weak var acceptancesStack: UIStackView!
    @IBOutlet weak var langaugesStack: UIStackView!
    
    let privacyCheckboxView = CheckboxView().fromNib()
    let useTermsCheckboxView = CheckboxView().fromNib()
    
    let langViews = [
        LanguageView().fromNib(),
        LanguageView().fromNib(),
        LanguageView().fromNib()
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        acceptancesStack.addArrangedSubview(privacyCheckboxView!)
        acceptancesStack.addArrangedSubview(useTermsCheckboxView!)
        
        langViews.forEach { (langView) in
            langaugesStack.addArrangedSubview(langView!)
        }
    }
}
