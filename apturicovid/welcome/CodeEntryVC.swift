import UIKit
import RxSwift
import SVProgressHUD
import CocoaLumberjack

enum CodeEntryMode {
    case sms
    case spkc
}

class CodeEntryVC: BaseViewController {
    
    enum ReturnMode { case dismiss, pop }
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var inputCodeLabel: UILabel!
    @IBOutlet weak var errorView: UIView!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var codeInputHolder: UIView!
    @IBOutlet weak var resendCodeView: UIView!
    @IBOutlet weak var resendCodeLabel: UILabel!
    @IBOutlet weak var backButton: RoundedButton!
        
    var pinInput = PinField()
    
    let offsetFromKeyboard: CGFloat = 8
    var uploadInprogress = false
    var keyboardFrame: CGRect?
    var lastCodeRequestTime: Date?
    
    @IBAction func onBackTap(_ sender: Any) {
        SVProgressHUD.dismiss()
        navigationController?.popViewController(animated: true)
    }
    
    deinit { SVProgressHUD.dismiss() }
    
    var requestResponse: PhoneVerificationRequestResponse?
    var phoneNumber: PhoneNumber?
    
    var mode: CodeEntryMode!
    var returnMode: ReturnMode = .pop
    
    let generator = UINotificationFeedbackGenerator()
    
    var errorFrame: CGRect? {
        
        guard !resendCodeLabel.isHidden || !errorView.isHidden else {return nil}
        
        if resendCodeLabel.isHidden {
            return stackView.convert(errorView.frame, to: view)
        } else {
            return stackView.convert(resendCodeView.frame, to: view)
        }
    }
    
    private func close() {
        LocalStore.shared.hasSeenIntro = true
        LocalStore.shared.setMobilephoneAndScheduleUpload(phone: phoneNumber)
        
        DispatchQueue.main.async {
            
            switch self.returnMode {
            case .pop:
                self.navigationController?.popToRootViewController(animated: true)
            case .dismiss:
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    private func clearPin(withError error: Error? = nil){
        
        pinInput.animateFailure(){ [weak self] in
            self?.pinInput.text = ""
            self?.showError(error != nil, with: "input_code_invalid")
        }
    }
    
    private func showError(_ show: Bool, with message: String? = nil) {
        DispatchQueue.main.async{
            
            self.errorView.isHidden = !show
            
            if show {
                self.errorLabel.text = message?.translated
                self.generator.notificationOccurred(.error)
                if let errorFrame = self.errorFrame {
                    self.scrollToVisibleFrame(errorFrame, animated: true)
                }
            }
        }
    }
    
    func scrollToVisibleFrame(_ frame: CGRect, animated: Bool){
        if let keyboardFrame = keyboardFrame {
            let intersection = keyboardFrame.intersection(frame)
            
            let overlap: CGFloat = {  if intersection.height < frame.height {
                return intersection.height
            } else {
                return intersection.height + frame.minY - keyboardFrame.minY
                }
            } ()
        
            if overlap > 0 {
                scrollView.scrollBy(CGPoint(x: 0, y: overlap), animated: animated)
            } else {
                scrollView.scrollRectToVisible(frame, animated: animated)
            }
        } else {
            scrollView.scrollRectToVisible(frame, animated: animated)
        }
        
    }
    
    private func styleErrorTextinput() {
        DispatchQueue.main.async {
            self.pinInput.appearance.backColor = UIColor(hex: "#F6E1E1")
        }
    }
    
    private func performSMSVerification(pin: String) {
           guard let response = requestResponse else { return }
           SVProgressHUD.show()
           
           ApiClient.shared.requestPhoneConfirmation(token: response.token, code: pin)
               .observeOn(MainScheduler.instance)
               .subscribe(onNext: { (result) in
                   SVProgressHUD.dismiss()
                   self.generator.notificationOccurred(.success)
                   
                   if result?.status == true {
                       self.phoneNumber?.token = response.token
                       self.close()
                   } else {
                        self.clearPin()
                   }
               }, onError: { [weak self] error in
                guard let `self` = self else { return }
                
                if Reachability.shared?.connection.available == true {
                    self.styleErrorTextinput()
                    self.clearPin(withError: error)
                } else {
                    Reachability.shared?.warnOfflineIfRequired(in: self)
                    self.clearPin()
                }
                SVProgressHUD.dismiss()
                justPrintError(error)
                
               })
               .disposed(by: disposeBag)
       }
    
    private func performExposureKeyUpload(pin: String) {
        uploadInprogress = true
        SVProgressHUD.show()
        ExposuresClient.shared.requestDiagnosisUploadKey(code: pin)
            .observeOn(MainScheduler.instance)
            .do(onError: { [weak self] error in
                
                guard let `self` = self else { return }
                
                if Reachability.shared?.connection.available == true {
                    self.styleErrorTextinput()
                    self.clearPin(withError: error)
                } else {
                    Reachability.shared?.warnOfflineIfRequired(in: self)
                    self.clearPin()
                }
            })
            .flatMap({ (response) -> Observable<Data> in
                guard let response = response else { return Observable.error(NSError.make("Unable to obtain upload token")) }

                return ExposureManager.shared.getAndPostDiagnosisKeys(token: response.token)
                    .do(onError: { [weak self] (err) in
                        self?.showBasicAlert(message: "error".translated)
                        justPrintError(err)
                    })
            })
            .subscribe(onNext: { [weak self] (data) in
                self?.uploadInprogress = false
                SVProgressHUD.dismiss()
                DispatchQueue.main.async {
                    guard let vc = self?.storyboard?.instantiateViewController(identifier: "NotificationSentVC") else { return }
                    self?.navigationController?.pushViewController(vc, animated: true)
                }
            }, onError: { [weak self] error in
                self?.uploadInprogress = false
                SVProgressHUD.dismiss()
                justPrintError(error)
            })
            .disposed(by: disposeBag)
    }
    
    override func translate() {
        let isSMS = mode == .sms
        
        titleLabel.text = isSMS ? "phone_confirmation_title".translated : "spkc_data_send".translated
        descriptionLabel.text = isSMS ? String(format: "phone_confirmation_description".translated, phoneNumber?.number ?? "") : "spkc_data_description".translated
        errorLabel.text = "input_code_invalid".translated
        inputCodeLabel.text = "enter_code".translated
        resendCodeLabel.text = errorView.isHidden ? "didnt_receive_code".translated : "resend_code".translated
    }
    
    func stylePinInput() {
        pinInput.keyboardType = .numberPad
        pinInput.textContentType = .oneTimeCode
        pinInput.properties.delegate = self
        pinInput.properties.numberOfCharacters = 8
        pinInput.properties.validCharacters = "0123456789+#"
        pinInput.properties.animateFocus = true
        pinInput.properties.isSecure = false
        pinInput.appearance.textColor = UIColor(hex: "#161B28")
        pinInput.appearance.backColor = UIColor(hex: "#F2F3F0")
        pinInput.appearance.backBorderWidth = 5
        pinInput.appearance.kerning = UIScreen.main.bounds.width * 0.08
        pinInput.appearance.font = .menlo(20)
        
        let done = UIBarButtonItem(style: .Dismiss, target: self, action: #selector(keyboardDone))
        pinInput.setupToolBarWith(leftBarItems: nil, rightbaritems: [done])
    }
    
    @objc func keyboardDone(){
        pinInput.resignFirstResponder()
    }
    
    @objc private func resendCode() {
        guard let phoneNo = phoneNumber?.number else { return }
        
        if lastCodeRequestTime != nil {
            let secondsPassed = Int(Date().timeIntervalSince(lastCodeRequestTime!))
            if secondsPassed < 60 {
                showBasicAlert(message: String(format: "sms_timeout_error".translated, 60 - secondsPassed))
                return
            }
        }
        
        lastCodeRequestTime = Date()
        
        SVProgressHUD.show()
        
        ApiClient.shared.requestPhoneVerification(phoneNumber: phoneNo)
            .subscribe(onNext: { response in
                SVProgressHUD.dismiss()
                
                guard let response = response else {
                    DDLogError("Response empty after sms request")
                    return
                }
                
                self.requestResponse = response
            },onError: { error in
                SVProgressHUD.dismiss()
                justPrintError(error)
            })
            .disposed(by: disposeBag)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.delegate = self
        errorView.isHidden = true
        
        resendCodeLabel.isHidden = mode == .spkc
        resendCodeLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(resendCode)))
        
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
                
                self.scrollView.contentInset.bottom = (self.keyboardFrame ?? .zero).inset(by: insets).height + self.offsetFromKeyboard
                
                }, onError: justPrintError)
            .disposed(by: disposeBag)
        
        //MARK: KeyboardDidShow
        NotificationCenter.default.rx
                   .notification(UIResponder.keyboardDidShowNotification)
                   .subscribe(onNext: { [weak self] notification in
                    guard let errorFrame = self?.errorFrame else { return }
                    self?.scrollToVisibleFrame(errorFrame, animated: true)

                    }, onError: justPrintError)
            .disposed(by: disposeBag)
        
        //MARK: KeyboardWillHide
        NotificationCenter.default.rx
            .notification(UIResponder.keyboardWillHideNotification)
            .subscribe(onNext: { [weak self] _ in
                self?.keyboardFrame = nil
                self?.scrollView.contentInset.bottom = self?.keyboardFrame?.height ?? 0
                }, onError: justPrintError)
            .disposed(by: disposeBag)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        codeInputHolder.addSubviewWithInsets(pinInput)
        stylePinInput()
    }
}

extension CodeEntryVC : UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        backButton.updateShadowOpacity(fromContentOffset: scrollView.contentOffset,
                                       shadowApplyBeginOffset: 0,
                                       shadowApplyIntensity: 200,
                                       shadowMaxOpasity: 0.3)
    }
}

extension CodeEntryVC: PinFieldDelegate {
    func pinField(_ field: PinField, didChangeTo string: String, isValid: Bool) {
        if string.count < field.properties.numberOfCharacters {
            errorView.isHidden = true
        }
        guard pinInput.text != field.text?.uppercased() else { return }
        pinInput.text = string.uppercased()
        pinInput.reloadAppearance()
    }
    func pinField(_ field: PinField, didFinishWith code: String) {
        // Called twice
        guard !uploadInprogress else { return }
        
        if mode == .sms {
            performSMSVerification(pin: code)
        } else {
            performExposureKeyUpload(pin: code)
        }
    }
}
