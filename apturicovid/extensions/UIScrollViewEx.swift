import UIKit.UIScrollView

extension UIScrollView {
    
    /// Sets content offset to the top.
    func resetScrollToInsts(animated: Bool, aditinalOffset: CGPoint = .zero) {
        
        let offset = CGPoint(x: contentInset.left + aditinalOffset.x, y: -(contentInset.top+aditinalOffset.y))
        
        guard contentOffset != offset else { return }
        
        UIView.animate(withDuration: animated ? 0.5 : 0) {
            self.contentOffset = offset
        }
    }
    
    /// Sets content offset to the bottom.
    func scrollToBottom(animated: Bool) {
        if contentSize.height < bounds.size.height { return }
        let bottomOffset = CGPoint(x: 0, y: contentSize.height + contentInset.bottom - bounds.size.height)
        setContentOffset(bottomOffset, animated: animated)
    }
    
    func scrollBy(_ offset: CGPoint, animated: Bool) {
        setContentOffset(contentOffset + offset, animated: animated)
    }
}
