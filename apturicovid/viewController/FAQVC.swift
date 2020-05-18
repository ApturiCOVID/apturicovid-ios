import UIKit

class FAQViewController: BaseViewController {
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
        FAQ(title: "Kā tiek apstrādāti mani dati?", description: "Viss ir super droši, neviens pie taviem datiem netiek, kaut kāds apraksts par šo tēmu."),
        FAQ(title: "Test", description: "Viss ir super droši, neviens pie taviem datiem netiek, kaut kāds apraksts par šo tēmu."),
        FAQ(title: "Test", description: "Viss ir super droši, neviens pie taviem datiem netiek, kaut kāds apraksts par šo tēmu.Viss ir super droši, neviens pie taviem datiem netiek, kaut kāds apraksts par šo tēmu.Viss ir super droši, neviens pie taviem datiem netiek, kaut kāds apraksts par šo tēmu.Viss ir super droši, neviens pie taviem datiem netiek, kaut kāds apraksts par šo tēmu.Viss ir super droši, neviens pie taviem datiem netiek, kaut kāds apraksts par šo tēmu.Viss ir super droši, neviens pie taviem datiem netiek, kaut kāds apraksts par šo tēmu.Viss ir super droši, neviens pie taviem datiem netiek, kaut kāds apraksts par šo tēmu.Viss ir super droši, neviens pie taviem datiem netiek, kaut kāds apraksts par šo tēmu.Viss ir super droši, neviens pie taviem datiem netiek, kaut kāds apraksts par šo tēmu.Viss ir super droši, neviens pie taviem datiem netiek, kaut kāds apraksts par šo tēmu.Viss ir super droši, neviens pie taviem datiem netiek, kaut kāds apraksts par šo tēmu.Viss ir super droši, neviens pie taviem datiem netiek, kaut kāds apraksts par šo tēmu.Viss ir super droši, neviens pie taviem datiem netiek, kaut kāds apraksts par šo tēmu.")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        faqs.forEach { (faq) in
            let questionView = QuestionView()
            questionView.fillWith(faq: faq)
            mainStackView.addArrangedSubview(questionView)
        }
        
        infoHolder.roundCorners(corners: [.bottomLeft, .bottomRight], radius: 30)
        
        mainScrollView.contentInsetAdjustmentBehavior = .never
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
