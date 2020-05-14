import UIKit
import RxSwift
import RxCocoa

class WelcomeVC: BaseViewController {
    
    private enum Link: String {
        case Privacy, Terms
        var url: String {
            //TODO: return link for webview
            return ""
        }
    }
    
    @IBOutlet weak var acceptancesStack: UIStackView!
    @IBOutlet weak var langaugesStack: UIStackView!
    @IBOutlet weak var headingLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var nextButton: RoundedButton!
    
    @IBAction func nextTap(_ sender: Any) {
        
    }
    
    let privacyAndTermsCheckboxView = CheckboxView.create(text: "", isChecked: false)
    let langViews = Language.allCases.map{ LanguageView.create($0) }
    
    //MARK: Text attributes:
    let linkFont = UIFont.systemFont(ofSize: 14, weight: .medium)
    
    let paragraphStyle: NSMutableParagraphStyle = {
        let p = NSMutableParagraphStyle()
        p.lineHeightMultiple = 1.4
        return p
    }()
    
    lazy var bodyAttributes: NSStringAttributes = {
        [
            .font : UIFont.systemFont(ofSize: 15, weight: .thin),
            .paragraphStyle : paragraphStyle
        ]
    }()
    
    lazy var privacyAndTermsAttributes: NSStringAttributes = {
        [
            .font : UIFont.systemFont(ofSize: 14, weight: .light),
            .paragraphStyle : paragraphStyle
        ]
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLanguageSelector()
        setupPrivacyAndTermsCheckBox()
    }
    
    private func setupLanguageSelector(){
        langViews.forEach { langView in
            
            langaugesStack.addArrangedSubview(langView)
            
            langView.translatesAutoresizingMaskIntoConstraints = false
            langView.widthAnchor.constraint(equalTo:langaugesStack.heightAnchor).isActive = true
            langView.heightAnchor.constraint(equalTo:langaugesStack.heightAnchor).isActive = true
           
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
        privacyAndTermsCheckboxView.bodyLabel.delegate = self
        
    }
    
    override func translate() {
        headingLabel.text = "welcome_title".translated
        nextButton.setTitle("welcome_continue".translated, for: .normal)
        
        // Body attributed text
        bodyLabel.attributedText =
            NSAttributedString(string: "welcome_app_description".translated,
                               attributes: bodyAttributes)
        
        // Privacy & Terms attributed text
        let privacyAttributedString =
            NSMutableAttributedString(string: "welcome_privacy_note".translated,
                                      attributes: privacyAndTermsAttributes)
        
       
        privacyAttributedString.setAsLink(text: "welcome_privacy_link".translated,
                                          linkURL: Link.Privacy.rawValue,
                                          font: linkFont)
                                      
        
        privacyAttributedString.setAsLink(text: "welcome_terms_link".translated,
                                          linkURL: Link.Terms.rawValue,
                                          font: linkFont)
                                         
        
        privacyAndTermsCheckboxView.attributedText = privacyAttributedString
    }
}

// MARK: LinkLabelDelegate
extension WelcomeVC: LinkLabelDelegate {
    func linkLabel(_ label: LinkLabel, didTapUrl url: String, atRange range: NSRange) {
        guard let link = Link(rawValue: url) else { return }
        print(link)
        //TODO: open link
    }
}




