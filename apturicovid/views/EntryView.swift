import UIKit
import RxSwift
import RxCocoa

class EntryStackView: UIStackView {
    var activate: (() -> Void)?
    override func accessibilityActivate() -> Bool {
        activate?()
        return true
    }
}

class EntryView: UIView {
    let numberOfDigits = 8
    
    var keyboardType: UIKeyboardType = .default {
        didSet {
            textFields.forEach{ $0.keyboardType = keyboardType }
        }
    }
    
    var textFields = [UITextField]()
    var stackView: EntryStackView?
    
    var disposeBag = DisposeBag()
    
    var text: String {
        textFields.map { $0.text ?? "" }.joined()
    }
    
    var textDidChange: (() -> Void)?
    
    func combinedAccessibilityTextFieldValues() -> String {
        var string = ""
        for textField in textFields {
            string += textField.accessibilityValue ?? ""
        }
        return string
    }
    
    init() {
        super.init(frame: .zero)
        
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setup()
    }
    
    override func resignFirstResponder() -> Bool {
        textFields.reduce(false) { (acc, textField) -> Bool in
            acc || textField.resignFirstResponder()
        }
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        print(textField)
    }
    
    private func autoFill(text: String) {
        for (index, input) in textFields.enumerated() {
            let charIndex = text.index(text.startIndex, offsetBy: index)
            input.text = String(text[charIndex])
        }
    }
    
    private func setup() {
        backgroundColor = .clear
        layer.cornerRadius = 20.0
        layer.cornerCurve = .continuous
        
        for _ in 0..<numberOfDigits {
            let textField = UITextField2()
            textField.adjustsFontForContentSizeCategory = true
            textField.font = UIFont.preferredFont(forTextStyle: .largeTitle)
            textField.textAlignment = .center
            textField.borderStyle = .none
            textField.backgroundColor = Colors.gray
            textField.layer.cornerRadius = 8.0
            textField.layer.cornerCurve = .continuous
            textField.delegate = self
            textField.isAccessibilityElement = false
            textField.autocapitalizationType = .allCharacters
            textFields.append(textField)
        }
        
        let entryStackView = UIStackView(arrangedSubviews: textFields)
        entryStackView.axis = .horizontal
        entryStackView.distribution = .fillEqually
        entryStackView.spacing = 8.0
        
        let stackView = EntryStackView(arrangedSubviews: [entryStackView])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 8.0
        stackView.accessibilityTraits = textFields[0].accessibilityTraits
        stackView.isAccessibilityElement = true
        
        let textField1 = textFields[0]
        stackView.activate = {
            textField1.becomeFirstResponder()
        }
        self.stackView = stackView
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            entryStackView.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            entryStackView.heightAnchor.constraint(greaterThanOrEqualToConstant: 40.0),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12.0),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12.0),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 12.0),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12.0)
        ])
    }
}

extension EntryView: UITextFieldDelegate2 {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if range == NSRange(location: 0, length: 0) && string.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let text = textField.text
                if text?.count == 8 {
                    self.autoFill(text: text ?? "")
                }
            }
            
            return false
        }
        
        textField.text = string
        let index = textFields.firstIndex(of: textField)!
        if string.isEmpty {
            if index > 1 {
                textFields[index - 1].becomeFirstResponder()
            } else {
                textField.resignFirstResponder()
            }
        } else {
            if index < numberOfDigits - 1 {
                textFields[index + 1].becomeFirstResponder()
            } else {
                textField.resignFirstResponder()
            }
        }
        textDidChange?()
        stackView?.accessibilityValue = combinedAccessibilityTextFieldValues()
        return false
    }
    
    func deletePressed(_ textField: UITextField2) {
        guard textField.text?.isEmpty ?? true else { return }
        
        let index = textFields.firstIndex(of: textField)!
        
        if index > 0 {
            textFields[index - 1].text = ""
            textFields[index - 1].becomeFirstResponder()
        }
    }
}
