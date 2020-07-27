import UIKit

class AutoLayoutButton: UIButton {
    override var intrinsicContentSize: CGSize {
       let labelSize = titleLabel?.sizeThatFits(CGSize(width: frame.width, height: .greatestFiniteMagnitude)) ?? .zero
       let desiredButtonSize = CGSize(width: labelSize.width + titleEdgeInsets.left + titleEdgeInsets.right, height: labelSize.height + titleEdgeInsets.top + titleEdgeInsets.bottom)

       return desiredButtonSize
    }
}
