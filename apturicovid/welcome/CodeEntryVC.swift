import UIKit
import RxSwift
import SVProgressHUD
import KAPinField
import CocoaLumberjack

enum CodeEntryMode {
    case sms
    case spkc
}

class CodeEntryVC: BaseViewController {
    
    enum ReturnMode { case dismiss, pop }
    
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
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
        
    var pinInput = KAPinField()
    
    var uploadInprogress = false
    
    var lastCodeRequestTime: Date?
    
    @IBAction func onBackTap(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    var requestResponse: PhoneVerificationRequestResponse?
    var phoneNumber: PhoneNumber?
    
    var mode: CodeEntryMode!
    var returnMode: ReturnMode = .pop
    
    
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
    
    private func performSMSVerification(pin: String) {
        guard let response = requestResponse else { return }
        SVProgressHUD.show()
        
        ApiClient.shared.requestPhoneConfirmation(token: response.token, code: pin)
            .subscribe(onNext: { (result) in
                SVProgressHUD.dismiss()
                if result?.status == true {
                    self.phoneNumber?.token = response.token
                    self.close()
                }
            }, onError: { error in
                SVProgressHUD.dismiss()
                self.showError(true, with: "input_code_invalid")
                self.styleErrorTextinput()
                self.pinInput.animateFailure()
                justPrintError(error)
            })
            .disposed(by: disposeBag)
    }
    
    private func showError(_ show: Bool, with message: String) {
        DispatchQueue.main.async {
            self.errorView.isHidden = !show
            self.errorLabel.text = message.translated
        }
    }
    
    private func styleErrorTextinput() {
        DispatchQueue.main.async {
            self.pinInput.appearance.backColor = UIColor(hex: "#F6E1E1")
        }
    }
    
    private func performExposureKeyUpload(pin: String) {
        uploadInprogress = true
        SVProgressHUD.show()
        ExposuresClient.shared.requestDiagnosisUploadKey(code: pin)
            .do(onError: { _ in
                self.styleErrorTextinput()
                self.pinInput.animateFailure()
                self.showError(true, with: "input_code_invalid")
            })
            .flatMap({ (response) -> Observable<Data> in
                guard let response = response else { return Observable.error(NSError.make("Unable to obtain upload token")) }

                return ExposureManager.shared.getAndPostDiagnosisKeys(token: response.token)
                    .do(onError: { (err) in
                        self.showBasicAlert(message: err.localizedDescription)
                    })
            })
            .subscribe(onNext: { (data) in
                self.uploadInprogress = false
                SVProgressHUD.dismiss()
                DispatchQueue.main.async {
                    guard let vc = self.storyboard?.instantiateViewController(identifier: "NotificationSentVC") else { return }
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }, onError: { error in
                self.uploadInprogress = false
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
        
        resendCodeLabel.isHidden = mode == .spkc
        resendCodeLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(resendCode)))

        NotificationCenter.default.rx
            .notification(UIResponder.keyboardWillShowNotification)
            .subscribe(onNext: { [weak self] notification in
                guard
                    let self = self,
                    let keyboardFrame: CGRect = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
                    else { return }
                
                self.bottomConstraint.constant = keyboardFrame.height + 5
                
                self.scrollView.scrollRectToVisible(self.stackView.bounds, animated: true)
                }, onError: justPrintError)
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx
            .notification(UIResponder.keyboardDidHideNotification)
            .subscribe(onNext: { [weak self] (_) in
                self?.bottomConstraint.constant = 0
                }, onError: justPrintError)
            .disposed(by: disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        codeInputHolder.addSubviewWithInsets(pinInput)
        stylePinInput()
    }
}

extension CodeEntryVC: KAPinFieldDelegate {
    func pinField(_ field: KAPinField, didChangeTo string: String, isValid: Bool) {
        if string.count < field.properties.numberOfCharacters {
            errorView.isHidden = true
        }
        guard pinInput.text != field.text?.uppercased() else { return }
        pinInput.text = string.uppercased()
        pinInput.reloadAppearance()
    }
    func pinField(_ field: KAPinField, didFinishWith code: String) {
        // Called twice
        guard !uploadInprogress else { return }
        
        if mode == .sms {
            performSMSVerification(pin: code)
        } else {
            performExposureKeyUpload(pin: code)
        }
    }
}
