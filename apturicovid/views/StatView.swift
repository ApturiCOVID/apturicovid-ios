import UIKit

class StatView: UIView {
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        layer.cornerRadius = 10
        clipsToBounds = true
    }
}
