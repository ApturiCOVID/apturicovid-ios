import UIKit
import RxSwift

class BaseViewController: UIViewController {
    private var notificationDisposable: Disposable?
    var connectionWarningView: WarningView?
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
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
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
        alert.addAction(UIAlertAction(title: "ok".translated, style: .cancel, handler: { (_) in
            alert.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func showBasicPrompt(
        with message: String,
        action: @escaping @autoclosure () -> Void,
        cancelAction: @escaping @autoclosure () -> Void = (),
        confirmTitle: String? = nil,
        cancelTitle: String? = nil
    ) {
        let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alert.overrideUserInterfaceStyle = .light
        alert.addAction(UIAlertAction(title: cancelTitle ?? "no".translated, style: .cancel, handler: { (_) in
            alert.dismiss(animated: true, completion: nil)
            cancelAction()
        }))
        alert.addAction(UIAlertAction(title: confirmTitle ?? "yes".translated, style: .default, handler: { _ in
            action()
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake && debugMenuEnabled {
            if let vc = UIStoryboard(name: "DebugMenu", bundle: nil).instantiateInitialViewController() {
                self.present(vc, animated: true, completion: nil)
            }
        }
    }
}

//MARK: NetworkLossWarning:

typealias AnimationStep = () -> ()

extension BaseViewController {
    
    func showConnectivityWarningIfRequired(){
        guard let connection = Reachability.shared?.connection else { return }
        if connection.available {
            hideNetworkWarningBox()
        } else {
            showNetworkWarningBox()
        }
    }
    
    @objc func notifyConnectionStateChanged(_ sender: Notification){
        
        guard let connection = sender.object as? Reachability.Connection else { return }
        
        if connection == .unavailable {
            showNetworkWarningBox()
        } else {
            hideNetworkWarningBox()
        }
    }
    
    /// Hides "No Internet" warning view.
    @objc func hideNetworkWarningBox(){
        animateDisappear(){
            self.connectionWarningView?.removeFromSuperview()
            self.connectionWarningView = nil
        }
    }
    
    /// Shows "No Internet" warning view.
    fileprivate func showNetworkWarningBox(){
        
        if connectionWarningView != nil {return}
        
        let warningBoxSize = CGSize(width: view.bounds.width, height: 70)
        let frame = CGRect(origin: .zero, size: warningBoxSize)
    
        var params = WarningViewParams()
        params.imageSize = CGSize(width: 30, height: 30)
        params.alignment = .center
        params.textAllignment = .center
        params.imageViewInsets = UIEdgeInsets(top: 0, left: 16, bottom: 16, right: 0)
        params.textViewInsets  = UIEdgeInsets(top: 0, left: 16, bottom: 20, right: 8)
        
        connectionWarningView = WarningView(frame: frame,
                                            text: "connectivity_offline".translated,
                                            params: params,
                                            preferedEffect: UIBlurEffect(style: .dark) )
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideNetworkWarningBox))
        connectionWarningView?.addGestureRecognizer(tap)
        animateAppear()
    }
    
    /// Animates appearing of "No Internet" warning view.
    fileprivate func animateAppear(){
        guard let connectionWarningView = connectionWarningView else { return }
        let animations = getAnimationInSteps()
        animations[0]()
        view.addSubview(connectionWarningView)
        setupWarningConstraints()
        
        UIView.animate(withDuration: 0.3, animations: {
            animations[1]()
        }) { _ in
            UIView.animate(withDuration: 0.2) {
                animations[2]()
            }
        }
    }
    
    /// Animates disappearing of "No Internet" warning view.
    fileprivate func animateDisappear(_ completed: @escaping () -> ()){
        let animations = getAnimationInSteps()
        UIView.animate(withDuration: 0.2, animations: {
            animations[1]()
        }, completion: { _ in
            UIView.animate(withDuration: 0.3, animations: {
                animations[0]()
            }, completion: { _ in completed() })
        })
    }
    
    fileprivate func getAnimationInSteps() -> [AnimationStep] {
        return [moveWarningViewToStartPosition,moveWarningViewToMiddlePosition,moveWarningViewToEndPosition]
    }
    
    fileprivate func moveWarningViewToStartPosition(){
        guard let connectionWarningView = connectionWarningView else { return }
        connectionWarningView.transform = CGAffineTransform(translationX: 0, y: connectionWarningView.bounds.height * 3)
    }
    
    fileprivate func moveWarningViewToMiddlePosition(){
        guard let connectionWarningView = connectionWarningView else { return }
        connectionWarningView.transform = CGAffineTransform(translationX: 0, y: -(connectionWarningView.bounds.height/4))
    }
    
    fileprivate func moveWarningViewToEndPosition(){
        connectionWarningView?.transform = .identity
    }
    
    fileprivate func setupWarningConstraints(){
        guard let connectionWarningView = connectionWarningView else { return }
        connectionWarningView.translatesAutoresizingMaskIntoConstraints = false
        
        connectionWarningView.heightAnchor
            .constraint(equalToConstant: connectionWarningView.bounds.height)
            .isActive = true
        
        connectionWarningView.widthAnchor
            .constraint(equalToConstant: connectionWarningView.bounds.width)
            .isActive = true
        
        connectionWarningView.centerXAnchor
            .constraint(equalTo: view.centerXAnchor)
            .isActive = true
        
        connectionWarningView.bottomAnchor
            .constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant:0)
            .isActive = true
    }
}
