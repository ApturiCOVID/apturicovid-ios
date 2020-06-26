import UIKit

extension UITextField {
    
    func setupToolBarWith(leftBarItems: [UIBarButtonItem]? , rightbaritems: [UIBarButtonItem]? ) {

        let toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = true
        toolBar.tintColor = Colors.darkGreen
        toolBar.barTintColor = Colors.headerColor
        toolBar.sizeToFit()
        
        let left = leftBarItems ?? []
        let right = rightbaritems ?? []
        
        let spacing = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        toolBar.setItems( left + [spacing] + right, animated: false)
        toolBar.isUserInteractionEnabled = true
        inputAccessoryView = toolBar
    }
}

extension UIBarButtonItem {
    
    enum CommonStyle {
        
        case Dismiss
        
        var image: UIImage? {
            switch self {
            case .Dismiss:
                return UIImage(named: "down")
            }
        }
        
        var style: UIBarButtonItem.Style {
            switch self {
            case .Dismiss:
                return .done
            }
        }
    }
    
    convenience init(style: CommonStyle, target: Any, action: Selector) {
        self.init(image: style.image, style: style.style, target: target, action: action)
    }
    
}


