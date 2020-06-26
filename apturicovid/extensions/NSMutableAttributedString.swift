import UIKit

typealias NSStringAttributes = [NSAttributedString.Key : Any]

extension NSMutableAttributedString {
    
    @discardableResult
    func setAsLink(text: String, linkURL: String, font: UIFont? = nil) -> Bool {
        let foundRange = mutableString.range(of: text)
        guard foundRange.location != NSNotFound else { return false }
        
        var attributes: NSStringAttributes = [
            .attachment : linkURL,
            .foregroundColor: UIColor(named: "linkColor")!
            
        ]
        
        if let font = font {
            attributes[.font] = font
        }

        addAttributes(attributes, range: foundRange)
        return true
    }
}
