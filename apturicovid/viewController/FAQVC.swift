import UIKit

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
    
    let faqs = [
        FAQ(title: "faq_question_1", description: "faq_answer_1"),
        FAQ(title: "faq_question_2", description: "faq_answer_2"),
        FAQ(title: "faq_question_3", description: "faq_answer_3"),
        FAQ(title: "faq_question_4", description: "faq_answer_4"),
        FAQ(title: "faq_question_5", description: "faq_answer_5"),
        FAQ(title: "faq_question_6", description: "faq_answer_6"),
        FAQ(title: "faq_question_7", description: "faq_answer_7")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        faqs.forEach { (faq) in
            let questionView = QuestionView()
            questionView.backgroundColor = .white
            questionView.fillWith(faq: faq)
            mainStackView.addArrangedSubview(questionView)
        }
        
        infoHolder.roundCorners(corners: [.bottomLeft, .bottomRight], radius: 30)
        
        mainScrollView.delegate = self
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
    }
}

//MARK: - UIScrollViewDelegate
extension FAQViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.y + scrollView.contentInset.top
        statusBarBlurView.effect = offset > 0 ? UIBlurEffect(style: .light) : nil
    }
    
}

