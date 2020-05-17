import UIKit
import RxSwift
import SVProgressHUD
import KAPinField

enum CodeEntryMode {
    case sms
    case spkc
}

class CodeEntryVC: BaseViewController {
    @IBOutlet weak var codeInputHolder: UIView!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var inputCodeLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var codeMissingLabel: UILabel!
    
    var pinInput = KAPinField()
    
    var uploadInprogress = false
    
    @IBAction func onBackTap(_ sender: Any) {
        if let navigationController = self.navigationController {
            navigationController.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    var requestResponse: PhoneVerificationRequestResponse?
    var phoneNumber: PhoneNumber?
    
    var mode: CodeEntryMode!
    var presentedFromSettings = false
    
    private func close() {
        LocalStore.shared.hasSeenIntro = true
        LocalStore.shared.setMobilephoneAndScheduleUpload(phone: phoneNumber)
        
        DispatchQueue.main.async {
            if self.presentedFromSettings {
                self.navigationController?.popToRootViewController(animated: true)
            } else {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    private func performSMSVerification(pin: String) {
        guard let response = requestResponse else { return }
        SVProgressHUD.show()
        
        RestClient.shared.requestPhoneConfirmation(token: response.token, code: pin)
            .subscribe(onNext: { (result) in
                SVProgressHUD.dismiss()
                if result?.status == true {
                    self.phoneNumber?.token = response.token
                    self.close()
                }
            }, onError: { error in
                SVProgressHUD.dismiss()
                self.pinInput.animateFailure()
                justPrintError(error)
            })
            .disposed(by: disposeBag)
    }
    
    private func performExposureKeyUpload(pin: String) {
        uploadInprogress = true
        SVProgressHUD.show()
        RestClient.shared.requestDiagnosisUploadKey(code: pin)
            .do(onError: { _ in
                self.pinInput.animateFailure()
            })
            .flatMap({ (response) -> Observable<Data> in
                guard let response = response else { return Observable.error(NSError.make("Unable to obtain upload token")) }

                return ExposureManager.shared.getAndPostDiagnosisKeys(token: response.token)
                    .do(onError: { (err) in
                        self.showBasicAlert(message: "diagnosis_key_upload_error".translated)
                    })
            })
            .subscribe(onNext: { (data) in
                self.uploadInprogress = false
                SVProgressHUD.dismiss()
                DispatchQueue.main.async {
                    self.dismiss(animated: true, completion: nil)
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
        
        titleLabel.text = isSMS ? "phone_confirmation".translated : "spkc_data_send".translated
        
        descriptionLabel.text = isSMS ?
            "phone_confirmation_1".translated + " \(phoneNumber?.number ?? "") " + "phone_confirmation_2".translated : "spkc_data_description".translated
        
        inputCodeLabel.text = "input_code".translated
        codeMissingLabel.text = "didn_receive_code".translated
    }
    
    func stylePinInput() {
        pinInput.autocapitalizationType = .allCharacters
        pinInput.properties.delegate = self
        pinInput.properties.numberOfCharacters = 8
        pinInput.properties.validCharacters = "AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz0123456789+#"
        pinInput.properties.animateFocus = true
        pinInput.properties.isSecure = false
        pinInput.appearance.textColor = UIColor(hex: "#161B28")
        pinInput.appearance.backColor = UIColor(hex: "#F2F3F0")
        pinInput.appearance.backBorderWidth = 5
        pinInput.appearance.font = .courier(15)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        codeMissingLabel.isHidden = mode == .spkc
        
        NotificationCenter.default.rx
            .notification(UIResponder.keyboardWillShowNotification)
            .subscribe(onNext: { [weak self] notification in
                guard
                    let self = self,
                    let keyboardFrame: CGRect = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
                    else { return }
                
                self.bottomConstraint.constant = keyboardFrame.height
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
        
        pinInput.becomeFirstResponder()
    }
}

extension CodeEntryVC: KAPinFieldDelegate {
    func pinField(_ field: KAPinField, didChangeTo string: String, isValid: Bool) {
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
