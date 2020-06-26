import UIKit
import RxSwift
import SVProgressHUD

class PhoneSettingsVC: BaseViewController, PhoneVerificationProvider {
    @IBOutlet weak var mainStackView: UIStackView!
    @IBOutlet weak var nextButton: RoundedButton!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var backButton: RoundedButton!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var statusBarBlurView: UIVisualEffectView!
    @IBOutlet weak var fadeView: FadeView!
    
    let phoneView = PhoneSetupView().fromNib() as! PhoneSetupView
    let offsetFromKeyboard: CGFloat = 8
    var keyboardFrame: CGRect?
    
    @IBAction func onBackTap(_ sender: Any) {
        navigationController?.popViewController(animated: true)
        SVProgressHUD.dismiss()
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let containerFrame = mainStackView.convert(phoneView.frame, to: scrollView)
        scrollView.scrollRectToVisible(containerFrame, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nextButton.isEnabled = false
        scrollView.adjustContentInset(for: fadeView)
        scrollView.delegate = self
        fadeView.datasource = self
        
        mainStackView.addArrangedSubview(phoneView)
        
        if let phone = LocalStore.shared.phoneNumber {
            phoneView.fill(with: phone)
        }
        
        //MARK: AnonymousTap
        phoneView
            .anonymousTapObservable
            .subscribe(onNext: { (_) in
                self.presentAnonymousPrompt()
            })
            .disposed(by: disposeBag)
        
        //MARK: PhoneInfoValid
        phoneView
            .phoneValidObservable
            .subscribe(onNext: { (valid) in
                self.nextButton.isEnabled = valid
            })
            .disposed(by: disposeBag)
        
        //MARK: PhoneInfoTap
        phoneView
            .phoneInfoTapObservable
            .subscribe(onNext: { _ in
                guard let vc = self.storyboard?.instantiateViewController(identifier: "PhoneInfoVC") else { return }
                self.navigationController?.pushViewController(vc, animated: true)
            })
            .disposed(by: disposeBag)
        
        //MARK: KeyboardWillShow
        NotificationCenter.default.rx
            .notification(UIResponder.keyboardWillShowNotification)
            .subscribe(onNext: { [weak self] notification in
                
                guard let `self` = self else { return }
                
                let keyboarOffestInsets = UIEdgeInsets(top: -self.offsetFromKeyboard,
                                                       left: 0,
                                                       bottom: 0,
                                                       right: 0)
                
                self.keyboardFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?
                    .inset(by: keyboarOffestInsets)
                
                let insets = UIEdgeInsets.height(self.view.frame.maxY - self.scrollView.frame.maxY)
                self.scrollView.contentInset.bottom = (self.keyboardFrame ?? .zero).inset(by: insets).height
                
                }, onError: justPrintError)
            .disposed(by: disposeBag)
        
        //MARK: KeyboardWillHide
        NotificationCenter.default.rx
        .notification(UIResponder.keyboardWillHideNotification)
        .subscribe(onNext: { [weak self] _ in
            
            guard let `self` = self else { return }
            self.keyboardFrame = nil
            self.scrollView.contentInset = .zero
            self.scrollView.adjustContentInset(for: self.fadeView)
            
            }, onError: justPrintError)
        .disposed(by: disposeBag)
    }
    
    override func translate() {
        titleLabel.text = "specify_a_phone_number_title".translated
        nextButton.setTitle("next".translated, for: .normal)
    }
}

extension PhoneSettingsVC : UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        let offset = scrollView.contentOffset.y + scrollView.contentInset.top
        statusBarBlurView.effect = offset > -view.safeAreaInsets.top ? UIBlurEffect(style: .light) : nil

        backButton.updateShadowOpacity(fromContentOffset: scrollView.contentOffset,
                                       shadowApplyBeginOffset: 0,
                                       shadowApplyIntensity: 800,
                                       shadowMaxOpasity: 0.3)
    }
    
}

extension PhoneSettingsVC: FadeViewDatasource {
    
    func fadeView(_ fadeView: FadeView, notificationsForMaskEnable enable: Bool) -> [Notification.Name] {
         return enable ? [UIResponder.keyboardWillHideNotification] :  [UIResponder.keyboardWillShowNotification]
    }
}

