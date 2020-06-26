import UIKit
import RxSwift

class MainTabController: UITabBarController {
    private var notificationDisposable: Disposable?
    var disposeBag = DisposeBag()
    
    var homeViewController: BaseViewController?     { viewControllers?[0] as? BaseViewController }
    var statsViewController: BaseViewController?    { viewControllers?[1] as? BaseViewController }
    var faqViewController: BaseViewController?      { viewControllers?[2] as? BaseViewController }
    var settingsViewController: BaseViewController? { viewControllers?[3] as? BaseViewController }
    
    var offlineWarningViewControllers: [BaseViewController] { [homeViewController,statsViewController].compactMap{$0} }

    override func viewDidLoad() {
        super.viewDidLoad()
        notificationDisposable = NotificationCenter.default.rx
            .notification(.languageDidChange).subscribe(onNext: { [weak self] (_) in
                self?.translate()
                }, onError: justPrintError)
        overrideUserInterfaceStyle = .light
        
        NotificationCenter.default.rx
            .notification(UIApplication.didBecomeActiveNotification)
            .subscribe(onNext: { [weak self] (_) in
                self?.offlineWarningViewControllers.forEach{$0.showConnectivityWarningIfRequired()}
            })
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx
            .notification(.reachabilityChanged)
            .subscribe(onNext: { [weak self] _ in
                self?.offlineWarningViewControllers.forEach{$0.showConnectivityWarningIfRequired()}
            })
            .disposed(by: disposeBag)
        
        translate()
    }
    
    private func translate() {
        
        offlineWarningViewControllers.forEach{
            $0.connectionWarningView?.setText( "connectivity_offline".translated )
        }
        homeViewController?.tabBarItem.title = "home".translated
        statsViewController?.tabBarItem.title = "statistics".translated
        faqViewController?.tabBarItem.title = "information".translated
        settingsViewController?.tabBarItem.title = "settings".translated
    }
}
