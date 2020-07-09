import UIKit
import RxSwift
import SVProgressHUD
import ExposureNotification

class ExposureSetupVC: BaseViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var mainStackView: UIStackView!
    @IBOutlet weak var nextButton: RoundedButton!
    @IBOutlet weak var backButton: RoundedButton!
    @IBOutlet weak var contactTitle: UILabel!
    @IBOutlet weak var contactDescription: UILabel!
    @IBOutlet weak var activateSwitchTitle: UILabel!
    @IBOutlet weak var activateSwitchSubtitle: UILabel!
    @IBOutlet weak var exposureEnableSwitch: UISwitch!
    @IBOutlet weak var fadeView: FadeView!
    @IBOutlet weak var exposureActivateContainer: UIView!
    
    let phoneView = PhoneSetupView().fromNib() as! PhoneSetupView
    let offsetFromKeyboard: CGFloat = 8
    var keyboardFrame: CGRect?
    var phoneNumberHasValidFormat = false
    var exposureEnabled: Bool { exposureEnableSwitch.isOn }
    
    @IBAction func onSwitchChange(_ sender: UISwitch) {
        setExposureTracking(enabled: sender.isOn, referenceSwitch: sender, animated: true)
    }
    
    @IBAction func onBackTap(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    private func closeAndMarkSeen() {
        self.dismiss(animated: true, completion: nil)
        LocalStore.shared.hasSeenIntro = true
    }
    
    private func promptExposureOffAndClose() {
        showBasicPrompt(with: "exposure_off_setup_prompt".translated, action: self.closeAndMarkSeen() )
    }
    
    @IBAction func onNextTap(_ sender: Any) {
        if exposureEnabled {
            validatePhoneNumber(phoneView.getPhoneNumber(), onCompleted: .dismiss)
        } else {
            promptExposureOffAndClose()
        }
    }
    
    private func scrollToBottom(after delay: TimeInterval){
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let `self` = self else { return }
            
            let bottom = CGPoint(x: 0,
                                 y: self.scrollView.contentSize.height - self.scrollView.bounds.height )
            self.scrollView.setContentOffset(bottom, animated: true)
        }
    }
    
    private func presentAnonymousPrompt() {
        let alert = UIAlertController(title: "", message: "anonymous_prompt".translated, preferredStyle: .alert)
        alert.overrideUserInterfaceStyle = .light
        alert.addAction(UIAlertAction(title: "yes".translated, style: .default, handler: { [weak self] (_) in
            SVProgressHUD.dismiss()
            self?.closeAndMarkSeen()
        }))
        alert.addAction(UIAlertAction(title: "no".translated, style: .cancel, handler: { (_) in
            alert.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let containerFrame = mainStackView.convert(exposureActivateContainer.frame, to: scrollView)
        scrollView.scrollRectToVisible(containerFrame, animated: true)
    }
    
    override func viewDidLoad() {
        
        mainStackView.addArrangedSubview(phoneView)
        phoneView.isHidden = true
        scrollView.delegate = self
        scrollView.adjustContentInset(for: fadeView)
        fadeView.datasource = self
        
        super.viewDidLoad()
        
        //MARK: ExposureTrackingIsEnabled
        ExposureManager.shared.trackingIsWorkingObserver
            .distinctUntilChanged()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] enabled in
                self?.exposureEnableSwitch.setOn(enabled, animated: true)
                self?.updateViewAppearance()
                if enabled {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                         self?.scrollView.scrollToBottom(animated: true)
                    }
                }
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
                    .inset(by: keyboarOffestInsets) ?? .zero
                
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
            self.scrollView.contentInset.bottom = 0
            self.scrollView.adjustContentInset(for: self.fadeView)
            
            }, onError: justPrintError)
        .disposed(by: disposeBag)
        
        //MARK: DidBecomeActive
        NotificationCenter.default.rx
            .notification(UIApplication.didBecomeActiveNotification)
            .subscribe(onNext: { [weak self] (_) in
            self?.updateViewAppearance()
        }, onError: justPrintError)
        .disposed(by: disposeBag)
        
        //MARK: AnonymousTap
        phoneView.anonymousTapObservable
            .subscribe(onNext: { [weak self] (_) in
                self?.presentAnonymousPrompt()
            }, onError: justPrintError)
            .disposed(by: disposeBag)
        
        //MARK: PhoneValid
        phoneView.phoneValidObservable
            .subscribe(onNext: { [weak self] (valid) in
                self?.phoneNumberHasValidFormat = valid
                self?.updateViewAppearance()
            })
            .disposed(by: disposeBag)
        
        //MARK: PhoneInfoTap
        phoneView
            .phoneInfoTapObservable
            .subscribe(onNext: { [weak self] _ in
                let vc = UIStoryboard(name: "PhoneSettings", bundle: nil).instantiateViewController(identifier: "PhoneInfoVC")
                self?.navigationController?.pushViewController(vc, animated: true)
            })
            .disposed(by: disposeBag)
    }
    
    override func translate() {
        contactTitle.text = "contact_detection".translated
        contactDescription.text = "exposure_setup_description".translated
        activateSwitchTitle.text = "activate".translated
        activateSwitchSubtitle.text = "exposure_switch_subtitle".translated
        nextButton.setText("next".translated)
    }
    
    func updateViewAppearance(){
        phoneView.isHidden = !exposureEnableSwitch.isOn
        
        if exposureEnabled {
            nextButton.isEnabled = phoneNumberHasValidFormat
        } else {
            nextButton.isEnabled = true
            phoneView.phoneInput.text = ""
            phoneView.phoneInput.endEditing(true)
        }
        
    }
}

extension ExposureSetupVC: ContactDetectionToggleProvider, PhoneVerificationProvider {
    
    func phoneVerificationProvider(validationFinishedWith error: Error?) {
        updateViewAppearance()
    }
    
    func contactDetectionProvider(didReceiveError error: Error) {
        justPrintError(error)
    }
}

extension ExposureSetupVC : UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        backButton.updateShadowOpacity(fromContentOffset: scrollView.contentOffset,
                                       shadowApplyBeginOffset: 100,
                                       shadowApplyIntensity: 1000,
                                       shadowMaxOpasity: 0.3)
    }
}

extension ExposureSetupVC: FadeViewDatasource {
    
    func fadeView(_ fadeView: FadeView, notificationsForMaskEnable enable: Bool) -> [Notification.Name] {
         return enable ? [UIResponder.keyboardWillHideNotification] :  [UIResponder.keyboardWillShowNotification]
    }
}

