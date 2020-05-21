import UIKit
import RxSwift
import SVProgressHUD

class ExposureSetupVC: BaseViewController {
    @IBOutlet weak var scrollview: UIScrollView!
    @IBOutlet weak var mainStackView: UIStackView!
    @IBOutlet weak var scrollViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var nextButton: RoundedButton!
    
    @IBOutlet weak var contactTitle: UILabel!
    @IBOutlet weak var contactDescription: UILabel!
    @IBOutlet weak var activateSwitchTitle: UILabel!
    
    var exposureEnabled = false {
        didSet {
            phoneView.isHidden = !exposureEnabled
            if !exposureEnabled {
                nextButton.isEnabled = true
                phoneView.phoneInput.text = ""
            }
        }
    }
    
    let phoneView = PhoneSetupView().fromNib() as! PhoneSetupView
    
    @IBAction func onSwitchChange(_ sender: UISwitch) {
        ExposureManager.shared.toggleExposureNotifications(enabled: sender.isOn)
            .observeOn(MainScheduler.instance)
            .subscribe(onCompleted: {
                self.exposureEnabled = sender.isOn
                self.scrollToBottom(after: 0.3)

            }, onError: { error in
                justPrintError(error)
                sender.isOn = ExposureManager.shared.enabled
                self.exposureEnabled = ExposureManager.shared.enabled
            })
            .disposed(by: disposeBag)
    }
    
    @IBAction func onBackTap(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    private func closeAndMarkSeen() {
        self.dismiss(animated: true, completion: nil)
        LocalStore.shared.hasSeenIntro = true
    }
    
    private func promptExposureOffAndClose() {
        showBasicPrompt(with: "exposure_off_setup_prompt".translated) {
            self.closeAndMarkSeen()
        }
    }
    
    @IBAction func onNextTap(_ sender: Any) {
        if exposureEnabled {
            SVProgressHUD.show()
            ApiClient.shared.requestPhoneVerification(phoneNumber: phoneView.getPhoneNumber().number)
                .subscribe(onNext: { (response) in
                    SVProgressHUD.dismiss()
                    if let response = response {
                        DispatchQueue.main.async {
                            guard let vc = UIStoryboard(name: "CodeEntry", bundle: nil).instantiateInitialViewController() as? CodeEntryVC else { return }
                            vc.requestResponse = response
                            vc.phoneNumber = self.phoneView.getPhoneNumber()
                            vc.mode = .sms
                            self.navigationController?.pushViewController(vc, animated: true)
                        }
                    }
                }, onError: { error in
                    SVProgressHUD.dismiss()
                    justPrintError(error)
                })
                .disposed(by: disposeBag)
        } else {
            promptExposureOffAndClose()
        }
    }
    
    private func scrollToBottom(after delay: TimeInterval){
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let `self` = self else { return }
            
            let bottom = CGPoint(x: 0,
                                 y: self.scrollview.contentSize.height - self.scrollview.bounds.height )
            self.scrollview.setContentOffset(bottom, animated: true)
        }
    }
    
    private func presentAnonymousPrompt() {
        let alert = UIAlertController(title: "", message: "anonymous_prompt".translated, preferredStyle: .alert)
        alert.overrideUserInterfaceStyle = .light
        alert.addAction(UIAlertAction(title: "yes".translated, style: .default, handler: { (_) in
            self.closeAndMarkSeen()
        }))
        alert.addAction(UIAlertAction(title: "no".translated, style: .cancel, handler: { (_) in
            alert.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        
        mainStackView.addArrangedSubview(phoneView)
        phoneView.isHidden = true
        
        super.viewDidLoad()
        
        exposureEnabled = false
        
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
        
        phoneView.anonymousTapObservable
            .subscribe(onNext: { (_) in
                self.presentAnonymousPrompt()
            }, onError: justPrintError)
            .disposed(by: disposeBag)
        
        phoneView.phoneValidObservable
            .subscribe(onNext: { (valid) in
                if self.exposureEnabled {
                    self.nextButton.isEnabled = valid
                }
            })
            .disposed(by: disposeBag)
        
        phoneView
            .phoneInfoTapObservable
            .subscribe(onNext: { _ in
                let vc = UIStoryboard(name: "PhoneSettings", bundle: nil).instantiateViewController(identifier: "PhoneInfoVC")
                self.navigationController?.pushViewController(vc, animated: true)
            })
            .disposed(by: disposeBag)
    }
    
    override func translate() {
        contactTitle.text  = "contact_detection".translated
        contactDescription.text = "exposure_setup_description".translated
        activateSwitchTitle.text = "activate".translated
        nextButton.setTitle("continue".translated, for: .normal)
    }
}
