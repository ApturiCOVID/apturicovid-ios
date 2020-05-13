import UIKit
import Foundation
import RxSwift
import RxCocoa

class SettingsViewController: UIViewController {
    @IBOutlet weak var headerView: UIView! {
        didSet {
            headerView.layer.cornerRadius = 22
            headerView.clipsToBounds = true
        }
    }
    @IBOutlet weak var titleLabel: UILabel!
    @IBAction func languageEn(_ sender: Any) {
        language = "en"
    }
    @IBAction func languageLv(_ sender: Any) {
        language = "lv"
    }
    @IBAction func languageRu(_ sender: Any) {
        language = "ru"
    }
    @IBOutlet weak var submitButton: UIButton! {
        didSet {
            submitButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
            submitButton.layer.cornerRadius = 22
            submitButton.clipsToBounds = true
        }
    }
    
    private var notificationDisposable: Disposable?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        notificationDisposable = NotificationCenter.default.rx
            .notification(languageChangeNotification).subscribe(onNext: { [weak self] (_) in
                self?.translate()
            }, onError: justPrintError)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
     
        translate()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    private func translate() {
        titleLabel.text = "settings_title".translated
        submitButton.setTitle("settings_enter_code".translated, for: .normal)
        
        submitButton.sizeToFit()
    }
}
