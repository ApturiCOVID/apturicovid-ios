import UIKit

class FAQViewController: UIViewController {
    @IBOutlet weak var mainStackView: UIStackView!
    @IBOutlet weak var infoHolder: UIView!
    @IBOutlet weak var mainScrollView: UIScrollView!
    
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
}
