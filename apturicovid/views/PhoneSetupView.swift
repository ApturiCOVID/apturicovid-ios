import UIKit
import RxSwift
import RxCocoa

class PhoneSetupView: UIView {
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var phoneInputView: UIView!
    @IBOutlet weak var phoneInput: UITextField!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var anonymousButtonView: UIView!
    @IBOutlet weak var phoneExplanationButton: UIButton!
    @IBOutlet weak var stayAnonymousLabel: UILabel!
    
    let checkboxView = CheckboxView.create(text: "Norādīts citas kontaktpersonas numurs", isChecked: false)
    
    func getPhoneNumber() -> PhoneNumber {
        return PhoneNumber(number: phoneInput.text ?? "", otherParty: checkboxView.isChecked, token: nil)
    }
    
    var disposeBag = DisposeBag()
    var phoneNumber: PhoneNumber?
    
    var anonymousTapObservable = PublishSubject<Bool>()
    var phoneValidObservable = PublishSubject<Bool>()
    var phoneInfoTapObservable = PublishSubject<Bool>()
    
    func fill(with phone: PhoneNumber) {
        self.phoneNumber = phone
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        stackView.insertArrangedSubview(checkboxView, at: stackView.subviews.count - 2)
        stackView.setCustomSpacing(20, after: phoneInputView)
        stackView.setCustomSpacing(10, after: descriptionLabel)
        stackView.setCustomSpacing(20, after: checkboxView)
        phoneInputView.layer.cornerRadius = 5
        
        if let phone = phoneNumber {
            phoneInput.text = phone.number
            checkboxView.isChecked = phone.otherParty
        }
        
        anonymousButtonView
            .rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { (_) in
                self.anonymousTapObservable.onNext(true)
            }, onError: justPrintError)
            .disposed(by: disposeBag)
        
        phoneInput
            .rx
            .text
            .subscribe(onNext: { (text) in
                self.phoneValidObservable.onNext(text?.count == 8)
            })
            .disposed(by: disposeBag)
        
        phoneExplanationButton
            .rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { (_) in
                self.phoneInfoTapObservable.onNext(true)
            })
            .disposed(by: disposeBag)
        
    }
}
