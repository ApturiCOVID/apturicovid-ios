import UIKit
import RxSwift

class MainTabController: UITabBarController {
    private var notificationDisposable: Disposable?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        notificationDisposable = NotificationCenter.default.rx
            .notification(.languageDidChange).subscribe(onNext: { [weak self] (_) in
                self?.translate()
                }, onError: justPrintError)
        overrideUserInterfaceStyle = .light
        
        translate()
    }
    
    private func translate() {
        self.viewControllers?[0].tabBarItem.title = "home".translated
        self.viewControllers?[1].tabBarItem.title = "statistics".translated
        self.viewControllers?[2].tabBarItem.title = "information".translated
        self.viewControllers?[3].tabBarItem.title = "settings".translated
    }
}
