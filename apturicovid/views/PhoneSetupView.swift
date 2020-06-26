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
        PhoneNumber(number: phoneInput.text ?? "", otherParty: checkboxView.isChecked, token: nil)
    }
    
    var phoneExplanationTapDisposable: Disposable?
    var disposeBag = DisposeBag()
    var phoneNumber: PhoneNumber?
    
    let textBadColor = UIColor(named: "offColor") ?? .red
    let textGoodColor = UIColor.darkGray
    let requiredDigitCount = 8
    var phoneNumberHasCorrectFormat: Bool { phoneInput.text?.count == requiredDigitCount }
    
    var anonymousTapObservable = PublishSubject<Bool>()
    var phoneInfoTapObservable = PublishSubject<Bool>()
    lazy var phoneValidObservable = BehaviorSubject<Bool>(value: phoneNumberHasCorrectFormat)
    
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
    
    @objc func keyboardDone(){
        phoneInput.resignFirstResponder()
        phoneInput.textColor = phoneNumberHasCorrectFormat ? textGoodColor : textBadColor
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        stackView.insertArrangedSubview(checkboxView, at: stackView.subviews.count - 2)
        stackView.setCustomSpacing(20, after: phoneInputView)
        stackView.setCustomSpacing(10, after: descriptionLabel)
        stackView.setCustomSpacing(20, after: checkboxView)
        phoneInputView.layer.cornerRadius = 5
        
        let done = UIBarButtonItem(style: .Dismiss, target: self, action: #selector(keyboardDone))
        phoneInput.setupToolBarWith(leftBarItems: nil, rightbaritems: [done])
        
        checkboxView.checkBox
            .rx
            .controlEvent(.valueChanged)
            .subscribe(onNext: {
                LocalStore.shared.phoneNumber?.otherParty = self.checkboxView.isChecked
            })
            .disposed(by: disposeBag)
        
        anonymousButtonView
            .rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { _ in
                self.anonymousTapObservable.onNext(true)
            }, onError: justPrintError)
            .disposed(by: disposeBag)
        
        phoneInput
            .rx.text
            .do(onNext: { (text) in
                self.phoneInput.textColor = (text?.count ?? 0) <= self.requiredDigitCount ? self.textGoodColor : self.textBadColor
            })
            .subscribe(onNext: { (text) in
                self.phoneValidObservable.onNext(self.phoneNumberHasCorrectFormat)
            })
            .disposed(by: disposeBag)
        
        phoneExplanationTapDisposable?.dispose()
        phoneExplanationTapDisposable = phoneExplanationButton
            .rx.tapGesture()
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
