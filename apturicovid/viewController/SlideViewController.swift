import UIKit

public enum SlideControllerDirection {
    case top
    case bottom
    case left
    case right
}

class SlideViewController: UIViewController {
    
    var parentNavigationController: UINavigationController?
    
    func addBackground() {
        UIView.animateKeyframes(withDuration: 0.2, delay: 0.2, animations: {
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        }, completion: nil)
    }

    func closeView(direction: SlideControllerDirection) {
        view.backgroundColor = UIColor.clear
        
        let horizontal = direction == .left || direction == .right
        let vertical = direction == .top || direction == .bottom
        
        let hotizontalMultiplier: CGFloat = (direction == .left) ? -1 : 1
        let verticalMultiplier: CGFloat = (direction == .top) ? -1 : 1
        
        let screenSize = UIScreen.main.bounds.size
        let horizontalPoint = horizontal ? screenSize.width * hotizontalMultiplier : 0.0
        let verticalPoint = vertical ? screenSize.height * verticalMultiplier : 0.0
        
        UIView.animate(withDuration: 0.3, delay: 0.0, animations: {
            self.view.frame = CGRect(x: horizontalPoint, y: verticalPoint, width: screenSize.width, height: screenSize.height)
            self.view.layoutIfNeeded()
        }, completion: { _ in
            self.view.removeFromSuperview()
            self.removeFromParent()
        })
    }
}
