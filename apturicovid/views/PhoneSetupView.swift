import UIKit
import RxSwift
import RxCocoa

class PhoneSetupView: UIView {
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var phoneInputView: UIView!
    @IBOutlet weak var phoneInput: PhoneTextField!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var anonymousButtonView: UIView!
    @IBOutlet weak var phoneExplanationButton: UIButton!
    @IBOutlet weak var stayAnonymousLabel: UILabel!
    
    let checkboxView = CheckboxView.create(text: "specified_phone_number_is_of_another_person".translated, isChecked: false)
    
    func getPhoneNumber() -> PhoneNumber {
        return PhoneNumber(number: phoneInput.text ?? "", otherParty: checkboxView.isChecked, token: nil)
    }
    
    var phoneExplanationTapDisposable: Disposable?
    var disposeBag = DisposeBag()
    var phoneNumber: PhoneNumber?
    
    var anonymousTapObservable = PublishSubject<Bool>()
    var phoneValidObservable = PublishSubject<Bool>()
    var phoneInfoTapObservable = PublishSubject<Bool>()
    
    func fill(with phone: PhoneNumber) {
        self.phoneNumber = phone
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        if let phone = phoneNumber {
            phoneInput.text = phone.number
            checkboxView.isChecked = phone.otherParty
        }
        translate()
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        stackView.insertArrangedSubview(checkboxView, at: stackView.subviews.count - 2)
        stackView.setCustomSpacing(20, after: phoneInputView)
        stackView.setCustomSpacing(10, after: descriptionLabel)
        stackView.setCustomSpacing(20, after: checkboxView)
        phoneInputView.layer.cornerRadius = 5
        
        
        checkboxView.checkBox
            .rx
            .controlEvent(.valueChanged)
            .subscribe(onNext: { [weak self] in
                guard let `self` = self else { return }
                LocalStore.shared.phoneNumber?.otherParty = self.checkboxView.isChecked
            })
            .disposed(by: disposeBag)
        
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
        
        phoneExplanationTapDisposable?.dispose()
        phoneExplanationTapDisposable = phoneExplanationButton
            .rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] (_) in
                self?.phoneInfoTapObservable.onNext(true)
            }, onError: justPrintError)
    }
    
    private func translate() {
        descriptionLabel.text = "specify_a_phone_number_description".translated
        phoneExplanationButton.setTitle("why_specify_a_phone_number".translated, for: .normal)
        stayAnonymousLabel.text = "remain_anonymous".translated
    }
}
