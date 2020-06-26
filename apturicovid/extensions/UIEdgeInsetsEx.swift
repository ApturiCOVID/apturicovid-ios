import UIKit

extension UIEdgeInsets {
    
    static func width(_ width: CGFloat) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: width/2, bottom: 0, right: width/2)
    }
    
    static func height(_ height: CGFloat) -> UIEdgeInsets {
        return UIEdgeInsets(top: height/2, left: 0, bottom: height/2, right: 0)
    }
}
