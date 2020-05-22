import UIKit
import RxSwift

class PhoneSettingsVC: BaseViewController, PhoneVerificationProvider {
    @IBOutlet weak var mainStackView: UIStackView!
    @IBOutlet weak var nextButton: RoundedButton!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLabel: UILabel!
    
    let phoneView = PhoneSetupView().fromNib() as! PhoneSetupView
    
    @IBAction func onBackTap(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func onNextButtonTap(_ sender: Any) {
        nextButton.isEnabled = false
        validatePhoneNumber(phoneView.getPhoneNumber(), onCompleted: .pop)
    }
    
    func phoneVerificationProvider(validationFinishedWith error: Error?) {
        nextButton.isEnabled = true
    }
    
    private func deletePhoneAndClose() {
        LocalStore.shared.phoneNumber = nil
        navigationController?.popViewController(animated: true)
    }
    
    private func presentAnonymousPrompt() {
        let alert = UIAlertController(title: "", message: "anonymous_prompt".translated, preferredStyle: .alert)
        alert.overrideUserInterfaceStyle = .light
        alert.addAction(UIAlertAction(title: "yes".translated, style: .default, handler: { (_) in
            self.deletePhoneAndClose()
        }))
        alert.addAction(UIAlertAction(title: "no".translated, style: .cancel, handler: { (_) in
            alert.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nextButton.isEnabled = false
        
        mainStackView.addArrangedSubview(phoneView)
        
        if let phone = LocalStore.shared.phoneNumber {
            phoneView.fill(with: phone)
        }
        
        phoneView
            .anonymousTapObservable
            .subscribe(onNext: { (_) in
                self.presentAnonymousPrompt()
            })
            .disposed(by: disposeBag)
        
        phoneView
            .phoneValidObservable
            .subscribe(onNext: { (valid) in
                self.nextButton.isEnabled = valid
            })
            .disposed(by: disposeBag)
        
        phoneView
            .phoneInfoTapObservable
            .subscribe(onNext: { _ in
                guard let vc = self.storyboard?.instantiateViewController(identifier: "PhoneInfoVC") else { return }
                self.navigationController?.pushViewController(vc, animated: true)
            })
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx
            .notification(UIResponder.keyboardWillShowNotification)
            .subscribe(onNext: { [weak self] notification in
                guard
                    let self = self,
                    let keyboardFrame: CGRect = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
                    else { return }
                
                self.bottomConstraint.constant = keyboardFrame.height + 2
                
                }, onError: justPrintError)
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx
            .notification(UIResponder.keyboardDidHideNotification)
            .subscribe(onNext: { [weak self] (_) in
                self?.bottomConstraint.constant = 30
                }, onError: justPrintError)
            .disposed(by: disposeBag)
    }
    
    override func translate() {
        titleLabel.text = "specify_a_phone_number_title".translated
        nextButton.setTitle("next".translated, for: .normal)
    }
}
