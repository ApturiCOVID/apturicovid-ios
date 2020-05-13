import UIKit

extension UIColor {
    public convenience init(rgb: UInt, alpha: CGFloat) {
        self.init(
            red: CGFloat((rgb & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgb & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgb & 0x0000FF) / 255.0,
            alpha: alpha
        )
    }
    
    public convenience init(hex: String?) {
        if let hex = hex?.replacingOccurrences(of: "#", with: ""), let code = UInt(hex, radix: 16) {
            self.init(rgb: code, alpha: 1.0)
        } else {
            self.init(rgb: 0xFFFFFF, alpha: 1.0)
        }
    }
}
