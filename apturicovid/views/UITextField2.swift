import UIKit

// Inspired by: https://stackoverflow.com/a/6637821/683763

protocol UITextFieldDelegate2: UITextFieldDelegate {
    func deletePressed(_ textField: UITextField2)
}

class UITextField2: UITextField {
    override func deleteBackward() {
        super.deleteBackward()
        
        if let delegate = delegate as? UITextFieldDelegate2 {
            delegate.deletePressed(self)
        }
    }
}
