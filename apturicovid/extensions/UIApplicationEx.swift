import UIKit.UIApplication

extension UIApplication {
    
    static func openSettings(){
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
    }
    
}
