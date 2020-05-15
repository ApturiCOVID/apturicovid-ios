import UIKit
import RxSwift

class ExposureSetupVC: BaseViewController {
    @IBOutlet weak var scrollview: UIScrollView!
    @IBOutlet weak var mainStackView: UIStackView!
    @IBOutlet weak var scrollViewBottomConstraint: NSLayoutConstraint!
    
    var exposureEnabled = false {
        didSet {
            phoneView.isHidden = !exposureEnabled
        }
    }
    
    let phoneView = PhoneSetupView().fromNib() as! PhoneSetupView
    
    @IBAction func onSwitchChange(_ sender: UISwitch) {
//        ExposureManager.shared.toggleExposureNotifications(enabled: sender.isOn)
//            .subscribe(onCompleted: {
//                self.phoneView.isHidden = !sender.isOn
//            }, onError: { error in
//                justPrintError(error)
//                sender.isOn = ExposureManager.shared.enabled
//            })
        exposureEnabled = sender.isOn
    }
    
    @IBAction func onBackTap(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func onNextTap(_ sender: Any) {
        if exposureEnabled && phoneView.mode == .withPhone {
            RestClient.shared.requestPhoneVerification(phoneNumber: phoneView.getPhoneNumber().number)
            .subscribe(onNext: { (response) in
                if let response = response {
                    DispatchQueue.main.async {
                        guard let vc = UIStoryboard(name: "CodeEntry", bundle: nil).instantiateInitialViewController() as? CodeEntryVC else { return }
                        vc.requestResponse = response
                        vc.phoneNumber = self.phoneView.getPhoneNumber()
                        vc.mode = .sms
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                }
            })
            .disposed(by: disposeBag)
        } else {
            self.dismiss(animated: true, completion: nil)
            LocalStore.shared.isFirstLaunch = false
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mainStackView.addArrangedSubview(phoneView)
        phoneView.isHidden = true
        
        NotificationCenter.default.rx
            .notification(UIResponder.keyboardWillShowNotification)
            .subscribe(onNext: { [weak self] notification in
                guard
                    let self = self,
                    let keyboardFrame: CGRect = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
                    else { return }
                
                self.scrollViewBottomConstraint.constant = keyboardFrame.height - 20
                
                self.scrollview.scrollRectToVisible(self.phoneView.bounds, animated: true)
                }, onError: justPrintError)
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx
            .notification(UIResponder.keyboardDidHideNotification)
            .subscribe(onNext: { [weak self] (_) in
                self?.scrollViewBottomConstraint.constant = 20
                }, onError: justPrintError)
            .disposed(by: disposeBag)
    }
}
