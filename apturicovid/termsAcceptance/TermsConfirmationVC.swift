import UIKit

class TermsConfirmationVC: BaseViewController {
    @IBOutlet weak var mainStack: UIStackView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var languageStackHolder: UIView!
    @IBOutlet var nextButton: RoundedButton!
    
    let languageStack = LanguageStack()
    let privacyAndTermsCheckboxView = CheckboxView.create(text: "", isChecked: false)
    
    var linkFont: UIFont { UIFont.preferredFont(forTextStyle: .body)}
    let paragraphStylePrivacy: NSMutableParagraphStyle = {
        let p = NSMutableParagraphStyle()
        p.lineHeightMultiple = 1.4
        return p
    }()
    var privacyAndTermsAttributes: NSStringAttributes {
        [
            .font : UIFont.preferredFont(forTextStyle: .body),
            .paragraphStyle : paragraphStylePrivacy
        ]
    }
    
    @IBAction func onNextPress(_ sender: Any) {
        LocalStore.shared.acceptanceV2Confirmed = true
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        languageStackHolder.addSubviewWithInsets(languageStack)
        setupPrivacyAndTermsCheckBox()
    }
    
    override func translate() {
        titleLabel.text = "europe_support_title".translated
        descriptionLabel.text = "europe_support_description".translated
        nextButton.setTitle("next".translated, for: .normal)
        
        // Privacy & Terms attributed text
        let privacyAttributedString =
            NSMutableAttributedString(string: "v2_terms_label".translated,
                                      attributes: privacyAndTermsAttributes)
        
       
        privacyAttributedString.setAsLink(text: "v2_terms_link".translated,
                                          linkURL: Link.Terms.rawValue,
                                          font: linkFont)
                                      
        
        privacyAttributedString.setAsLink(text: "v2_privacy_link".translated,
                                          linkURL: Link.Privacy.rawValue,
                                          font: linkFont)
                                         
        
        privacyAndTermsCheckboxView.attributedText = privacyAttributedString
        privacyAndTermsCheckboxView.bodyLabel.setNeedsLayout()
        privacyAndTermsCheckboxView.bodyLabel.layoutIfNeeded()
    }
    
    private func setupPrivacyAndTermsCheckBox(){
        nextButton.isEnabled = false
        mainStack.addArrangedSubview(privacyAndTermsCheckboxView)
        
        // Enable next button when terms accepted
        privacyAndTermsCheckboxView.checkBox.rx.tap
            .map { self.privacyAndTermsCheckboxView.isChecked }
            .bind(to: nextButton.rx.isEnabled)
            .disposed(by: disposeBag)
        privacyAndTermsCheckboxView.bodyLabel.delegate = self
        privacyAndTermsCheckboxView.alignment = .center
    }
}

// MARK: LinkLabelDelegate
extension TermsConfirmationVC: LinkLabelDelegate {
    func linkLabel(_ label: LinkLabel, didTapUrl url: String, atRange range: NSRange) {
        guard let link = Link(rawValue: url) else { return }
        if UIApplication.shared.canOpenURL(link.url){
            UIApplication.shared.open(link.url, options: [:], completionHandler: nil)
        }
    }
}
