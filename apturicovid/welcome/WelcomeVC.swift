import UIKit
import RxSwift
import RxCocoa

class WelcomeVC: BaseViewController {
    
    @IBOutlet weak var spkcHeightConstaint: NSLayoutConstraint!
    @IBOutlet weak var langaugesStack: UIStackView!
    @IBOutlet weak var headingLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var nextButton: RoundedButton!
    @IBOutlet weak var mainStack: UIStackView!
    @IBOutlet weak var spkcLogo: UIImageView!
    
    let privacyAndTermsCheckboxView = CheckboxView.create(text: "", isChecked: false)
    let langViews = Language.allCases.map{ LanguageView.create($0) }
    
    //MARK: Text attributes:
    var linkFont:UIFont { UIFont.preferredFont(forTextStyle: .body)}
    
    let paragraphStyleBody: NSMutableParagraphStyle = {
        let p = NSMutableParagraphStyle()
        p.lineHeightMultiple = 1.4
        p.alignment = .center
        return p
    }()
    
    let paragraphStylePrivacy: NSMutableParagraphStyle = {
        let p = NSMutableParagraphStyle()
        p.lineHeightMultiple = 1.4
        return p
    }()
    
    var bodyAttributes: NSStringAttributes {
        [
            .font : UIFont.preferredFont(forTextStyle: .body),
            .paragraphStyle : paragraphStyleBody
        ]
    }
    
    var privacyAndTermsAttributes: NSStringAttributes {
        [
            .font : UIFont.preferredFont(forTextStyle: .body),
            .paragraphStyle : paragraphStylePrivacy
        ]
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.layer.removeAllAnimations()
        UIView.animate(withDuration: 1) { [weak self] in
            guard let `self` = self else { return }
            self.spkcLogo.alpha = self.spkcLogo.bounds.width > 50 ? 1 : 0
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLanguageSelector()
        setupPrivacyAndTermsCheckBox()
    }
    
    private func setupLanguageSelector(){
        langViews.forEach { langView in
            
            langView.isSelected = langView.language.isPrimary
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
        mainStack.insertArrangedSubview(privacyAndTermsCheckboxView, at: mainStack.arrangedSubviews.count - 2)
        
        // Enable next button when terms accepted
        privacyAndTermsCheckboxView.checkBox.rx.tap
            .map { self.privacyAndTermsCheckboxView.isChecked }
            .bind(to: nextButton.rx.isEnabled)
            .disposed(by: disposeBag)
        privacyAndTermsCheckboxView.bodyLabel.delegate = self
        privacyAndTermsCheckboxView.alignment = .center
        
    }
    
    override func translate() {
        headingLabel.text = "welcome_title".translated
        nextButton.setText("next".translated)
        
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
        privacyAndTermsCheckboxView.bodyLabel.setNeedsLayout()
        privacyAndTermsCheckboxView.bodyLabel.layoutIfNeeded()
        
    }
}

// MARK: LinkLabelDelegate
extension WelcomeVC: LinkLabelDelegate {
    func linkLabel(_ label: LinkLabel, didTapUrl url: String, atRange range: NSRange) {
        guard let link = Link(rawValue: url) else { return }
        if UIApplication.shared.canOpenURL(link.url){
            UIApplication.shared.open(link.url, options: [:], completionHandler: nil)
        }
    }
}
