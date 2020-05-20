import UIKit
import RxSwift

class BaseViewController: UIViewController {
    private var notificationDisposable: Disposable?
    var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        notificationDisposable = NotificationCenter.default.rx
            .notification(.languageDidChange).subscribe(onNext: { [weak self] (_) in
                self?.translate()
                }, onError: justPrintError)
        overrideUserInterfaceStyle = .light
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
     
        translate()
    }
    
    func translate() {
        // override this to translate VC labels
    }
    
    func showBasicAlert(message: String) {
        DispatchQueue.main.async {
            if let statusBarNotification = UIStoryboard(name: "StatusBarNotification", bundle: nil).instantiateInitialViewController() as? StatusBarNotification {
                statusBarNotification.text = message
                self.showSlideViewController(slideVC: statusBarNotification, direction: .top)
            }
        }
    }
    
    func showSlideViewController(slideVC: SlideViewController, direction: SlideControllerDirection) {
        self.view.addSubview(slideVC.view)
        self.addChild(slideVC)
        slideVC.view.layoutIfNeeded()
        
        let horizontal = direction == .left || direction == .right
        let vertical = direction == .top || direction == .bottom
        
        let hotizontalMultiplier: CGFloat = (direction == .left) ? -1 : 1
        let verticalMultiplier: CGFloat = (direction == .top) ? -1 : 1
        
        let screenSize = UIScreen.main.bounds.size
        let horizontalPoint = horizontal ? screenSize.width * hotizontalMultiplier : 0.0
        let verticalPoint = vertical ? screenSize.height * verticalMultiplier : 0.0
        
        slideVC.view.frame = CGRect(x: horizontalPoint, y: verticalPoint, width: screenSize.width, height: screenSize.height)
        
        if direction != .top { view.endEditing(true) }
        UIView.animate(withDuration: 0.2, animations: { () -> Void in
            slideVC.view.frame = CGRect(x: 0, y: 0, width: screenSize.width, height: screenSize.height)
        })
    }
    
    func presentErrorAlert(with message: String) {
        let alert = UIAlertController(title: "error".translated, message: message.translated, preferredStyle: .alert)
        alert.overrideUserInterfaceStyle = .light
        alert.addAction(UIAlertAction(title: "continue".translated, style: .cancel, handler: { (_) in
            alert.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func showBasicPrompt(
        with message: String,
        action: @escaping () -> Void,
        cancelAction: (() -> Void)? = nil,
        confirmTitle: String? = nil,
        cancelTitle: String? = nil
    ) {
        let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alert.overrideUserInterfaceStyle = .light
        alert.addAction(UIAlertAction(title: cancelTitle ?? "no".translated, style: .cancel, handler: { (_) in
            alert.dismiss(animated: true, completion: nil)
            cancelAction?()
        }))
        alert.addAction(UIAlertAction(title: confirmTitle ?? "yes".translated, style: .default, handler: { _ in
            action()
        }))
        self.present(alert, animated: true, completion: nil)
    }
}
