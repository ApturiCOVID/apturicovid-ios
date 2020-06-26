import UIKit

extension UISwitch {
    func setOffColor(_ color: UIColor){
        tintColor = color
        layer.cornerRadius = bounds.height / 2
        backgroundColor = color
    }
}
