import UIKit
import RxSwift

class BaseViewController: UIViewController {
    private var notificationDisposable: Disposable?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        notificationDisposable = NotificationCenter.default.rx
            .notification(.languageDidChange).subscribe(onNext: { [weak self] (_) in
            self?.translate()
        }, onError: justPrintError)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
     
        translate()
    }
    
    func translate() {
        // override this to translate VC labels
    }
}
