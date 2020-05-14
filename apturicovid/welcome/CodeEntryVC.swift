import UIKit

enum CodeEntryMode {
    case sms
    case spkc
}

class CodeEntryVC: BaseViewController {
    @IBOutlet weak var codeInputHolder: UIView!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var nextButtonBottomContraint: NSLayoutConstraint!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var inputCodeLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var codeMissingLabel: UILabel!
    @IBOutlet weak var nextButton: RoundedButton!
    
    
    @IBAction func onBackTap(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    var requestResponse: PhoneVerificationRequestResponse?
    var phoneNumber: String?
    
    var codeEntryView: EntryView!
    var mode: CodeEntryMode!
    
    private func performSMSVerification() {
        guard let response = requestResponse else { return }
        
        RestClient.shared.requestPhoneConfirmation(token: response.token, code: codeEntryView.text)
            .subscribe(onNext: { (result) in
                if result?.status == true {
                    DispatchQueue.main.async {
                        self.dismiss(animated: true, completion: nil)
                    }
                }
            }, onError: justPrintError)
            .disposed(by: disposeBag)
    }
    
    private func performExposureKeyUpload() {
        RestClient.shared.requestDiagnosisUploadKey(code: codeEntryView.text)
            .subscribe(onNext: { (data) in
                print(data)
            }, onError: justPrintError)
            .disposed(by: disposeBag)
    }
    
    @IBAction func onNextTap(_ sender: Any) {
        if mode == .sms {
            performSMSVerification()
        } else {
            performExposureKeyUpload()
        }
    }
    
    override func translate() {
        let isSMS = mode == .sms
        
        titleLabel.text = isSMS ? "phone_confirmation".translated : "spkc_data_send".translated
        
        descriptionLabel.text = isSMS ?
            "phone_confirmation_1".translated + " \(phoneNumber ?? "") " + "phone_confirmation_2".translated : "spkc_data_description".translated
        
        inputCodeLabel.text = "input_code".translated
        codeMissingLabel.text = "didn_receive_code".translated
        nextButton.setTitle("next".translated, for: .normal)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        codeEntryView = EntryView()
        codeInputHolder.addSubviewWithInsets(codeEntryView)
        
        codeMissingLabel.isHidden = mode == .spkc
        
        NotificationCenter.default.rx
            .notification(UIResponder.keyboardWillShowNotification)
            .subscribe(onNext: { [weak self] notification in
                guard
                    let self = self,
                    let keyboardFrame: CGRect = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
                    else { return }
                
                self.bottomConstraint.constant = keyboardFrame.height
                self.nextButtonBottomContraint.constant = keyboardFrame.height + 20
                }, onError: justPrintError)
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx
            .notification(UIResponder.keyboardDidHideNotification)
            .subscribe(onNext: { [weak self] (_) in
                self?.bottomConstraint.constant = 0
                self?.nextButtonBottomContraint.constant = 20
                }, onError: justPrintError)
            .disposed(by: disposeBag)
    }
}
