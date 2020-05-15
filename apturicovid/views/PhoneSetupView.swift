import UIKit
import RxSwift
import RxCocoa

enum UserMode {
    case anonymous
    case withPhone
}

class PhoneSetupView: UIView {
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var phoneInputView: UIView!
    @IBOutlet weak var phoneInput: UITextField!
    @IBOutlet weak var phoneSelectionImage: UIImageView!
    @IBOutlet weak var anonymousSelectionImage: UIImageView!
    @IBOutlet weak var withPhoneLabel: UILabel!
    @IBOutlet weak var anonymousLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    @IBOutlet weak var withPhoneView: UIView!
    @IBOutlet weak var anonymousView: UIView!
    
    var checkboxView: CheckboxView!
    
    var mode: UserMode = .withPhone {
        didSet {
            setupModeVisuals()
        }
    }
    
    func getPhoneNumber() -> PhoneNumber {
        return PhoneNumber(number: phoneInput.text ?? "", otherParty: checkboxView.isChecked)
    }
    
    var disposeBag = DisposeBag()
    
    private func setupModeVisuals() {
        let withPhone = mode == .withPhone
        let onImage = UIImage(named: "radio-selected")
        let offImage = UIImage(named: "radio-empty")
        
        phoneSelectionImage.image = withPhone ? onImage : offImage
        anonymousSelectionImage.image = withPhone ? offImage : onImage
        phoneInputView.isHidden = !withPhone
        checkboxView.isHidden = !withPhone
        
        if !withPhone {
            phoneInputView.endEditing(true)
        }
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        checkboxView = CheckboxView.create(text: "Norādīts citas kontaktpersonas numurs", isChecked: false)
        stackView.addArrangedSubview(checkboxView)
        stackView.setCustomSpacing(20, after: phoneInputView)
        stackView.setCustomSpacing(10, after: descriptionLabel)
        phoneInputView.layer.cornerRadius = 5
        
        withPhoneView
            .rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { _ in
                self.mode = .withPhone
            }, onError: justPrintError)
            .disposed(by: disposeBag)
        
        anonymousView
            .rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { _ in
                self.mode = .anonymous
            }, onError: justPrintError)
            .disposed(by: disposeBag)
    }
}
