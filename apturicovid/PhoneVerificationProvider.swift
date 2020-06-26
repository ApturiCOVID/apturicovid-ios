import RxSwift
import SVProgressHUD

protocol PhoneVerificationProvider: BaseViewController {
    func validatePhoneNumber(_ number: PhoneNumber, onCompleted returnMode: CodeEntryVC.ReturnMode )
    func phoneVerificationProvider(validationFinishedWith error: Error?)
}

extension PhoneVerificationProvider {
    
    func validatePhoneNumber(_ number: PhoneNumber, onCompleted returnMode: CodeEntryVC.ReturnMode) {
        SVProgressHUD.show()
        
        ApiClient.shared.requestPhoneVerification(phoneNumber: number.number)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (response) in
                
                SVProgressHUD.dismiss()
                guard let `self` = self else { return }
                
                if let response = response {
                    guard let vc = UIStoryboard(name: "CodeEntry", bundle: nil).instantiateInitialViewController() as? CodeEntryVC else { return }
                    vc.requestResponse = response
                    vc.phoneNumber = number
                    vc.mode = .sms
                    vc.returnMode = returnMode
                    self.navigationController?.pushViewController(vc, animated: true)
                } else {
                    self.presentErrorAlert(with: "invalid_phone_number_error")
                }
                self.phoneVerificationProvider(validationFinishedWith: nil)
            }, onError: { [weak self] error in
                SVProgressHUD.dismiss()
                justPrintError(error)
                
                guard let `self` = self else { return }
                
                if Reachability.shared?.connection.available == true {
                    self.presentErrorAlert(with: "invalid_phone_number_error")
                } else {
                    Reachability.shared?.warnOfflineIfRequired(in: self)
                }
                
                self.phoneVerificationProvider(validationFinishedWith: error)
            })
            .disposed(by: disposeBag)
    }
}
