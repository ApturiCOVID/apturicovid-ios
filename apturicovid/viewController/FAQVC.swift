import UIKit
import SafariServices

class FAQViewController: BaseViewController {
    @IBOutlet weak var statusBarBlurView: UIVisualEffectView!
    @IBOutlet weak var mainScrollView: UIScrollView!
    @IBOutlet weak var infoHolder: UIView!
    @IBOutlet weak var viewControllerTitleLabel: UILabel!
    @IBOutlet weak var viewControllerDescriptionLabel: UILabel!
    @IBOutlet weak var stackViewTitleLabel: UILabel!
    @IBOutlet weak var mainStackView: UIStackView!
    @IBOutlet weak var firstBulletPointLabel: UILabel!
    @IBOutlet weak var secondBulletPointLabel: UILabel!
    @IBOutlet weak var thirdBulletPointLabel: UILabel!
    @IBOutlet weak var fourthBulletPointLabel: UILabel!
    @IBOutlet weak var faqTitleLabel: UILabel!
    @IBOutlet weak var questionsStackView: UIStackView!
    @IBOutlet weak var privacyButton: UIButton!
    @IBOutlet weak var useTerms: UIButton!
    
    var faqs: [FAQ] {
        return [
            FAQ(title: "faq_question_1", description: "faq_answer_1"),
            FAQ(title: "faq_question_2", description: "faq_answer_2"),
            FAQ(title: "faq_question_3", description: "faq_answer_3"),
            FAQ(title: "faq_question_4", description: "faq_answer_4"),
            FAQ(title: "faq_question_5", description: "faq_answer_5"),
            FAQ(title: "faq_question_6", description: "faq_answer_6"),
            FAQ(title: "faq_question_7", description: "faq_answer_7"),
            FAQ(title: "faq_question_8", description: "faq_answer_8")
        ]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        infoHolder.roundCorners(corners: [.bottomLeft, .bottomRight], radius: 30)
        
        mainScrollView.delegate = self
        
        privacyButton
            .rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                let privacySafariVC = SFSafariViewController(url: Link.Privacy.url)
                self?.present(privacySafariVC, animated: true)
            }, onError: justPrintError)
            .disposed(by: disposeBag)
        
        useTerms
            .rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                let termsSafariVC = SFSafariViewController(url: Link.Privacy.url)
                self?.present(termsSafariVC, animated: true)
            }, onError: justPrintError)
            .disposed(by: disposeBag)
    }
    
    private func setupQuestionsView() {
        questionsStackView.subviews.forEach { $0.removeFromSuperview() }
        faqs.forEach { (faq) in
            let questionView = QuestionView()
            questionView.backgroundColor = Colors.headerColor
            questionView.fillWith(faq: faq)
            questionsStackView.addArrangedSubview(questionView)
        }
    }
    
    override func translate() {
        viewControllerTitleLabel.text = "what_is_contact_tracing".translated
        viewControllerDescriptionLabel.text = "contact_detection_explanation".translated
        stackViewTitleLabel.text = "what_about_my_privacy".translated
        firstBulletPointLabel.text = "data_is_kept_on_device_only".translated
        secondBulletPointLabel.text = "data_is_automatically_deleted".translated
        thirdBulletPointLabel.text = "anonymous_identity".translated
        fourthBulletPointLabel.text = "gpc_tracking_not_performed".translated
        faqTitleLabel.text = "frequently_asked_questions".translated
        
        privacyButton.setTitle("user_privacy".translated, for: .normal)
        useTerms.setTitle("user_terms".translated, for: .normal)
        
        setupQuestionsView()
    }
}

//MARK: - UIScrollViewDelegate
extension FAQViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.y + scrollView.contentInset.top
        statusBarBlurView.effect = offset > -view.safeAreaInsets.top ? UIBlurEffect(style: .light) : nil
    }
    
}

