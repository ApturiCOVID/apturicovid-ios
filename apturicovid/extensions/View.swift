import UIKit

extension UIView {
    func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
    
    public func addSubviewWithInsets(_ view: UIView, insets: UIEdgeInsets = UIEdgeInsets.zero) {
        view.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(view)
        
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(\(insets.top))-[view]-(\(insets.bottom))-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: ["view": view]))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-(\(insets.left))-[view]-(\(insets.right))-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: ["view": view]))
    }
    
    public func addSubview(_ view: UIView, block: (_ child: UIView, _ parent: UIView) -> Void) {
        view.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(view)
        
        block(view, self)
    }
    
    public func addSubview(_ view: UIView, block: (_ child: UIView) -> Void) {
        view.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(view)
        
        block(view)
    }
    
    @discardableResult
    func fromNib<T : UIView>() -> T? {
        guard let contentView = Bundle(for: type(of: self)).loadNibNamed(String(describing: type(of: self)), owner: self, options: nil)?.first as? T else {
            return nil
        }
        self.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        return contentView
    }
    
    func rotate(angle: CGFloat) {
        let radians = angle / 180.0 * CGFloat.pi
        let rotation = self.transform.rotated(by: radians)
        self.transform = rotation
    }
}
