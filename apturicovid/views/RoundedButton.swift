import UIKit

@IBDesignable class RoundedButton: UIButton {
    
    @IBInspectable var cornerRadius: CGFloat = 0.0 {
           didSet {
            let smallestSide = min(bounds.height, bounds.width)
            let safeValue = max(0, min(smallestSide/2, cornerRadius))
            layer.cornerRadius = safeValue
            }
       }
    
    override var isEnabled: Bool{
        didSet { alpha = isEnabled ? 1 : 0.6 }
    }
    
    @IBInspectable var shadowRadius: CGFloat = 0 {
        didSet  { applyShadow(shadowEnabled) }
    }
    
    @IBInspectable var shadowOpacity: CGFloat = 0 {
        didSet  { applyShadow(shadowEnabled) }
    }
    
    @IBInspectable var shadowColor: UIColor = .lightGray {
        didSet{ layer.shadowColor = shadowColor.cgColor }
    }
    
    private var shadowEnabled: Bool {shadowOpacity != 0}
    
    private func applyShadow(_ enabled: Bool){
        if enabled{
            layer.shadowRadius  = shadowRadius
            layer.shadowOpacity = Float(shadowOpacity)
            layer.shadowOffset = .zero
        } else {
            layer.shadowRadius  = 0
        }
    }
    
    func updateShadowOpacity(fromContentOffset contentOffset: CGPoint,
                             shadowApplyBeginOffset: CGFloat,
                             shadowApplyIntensity: CGFloat,
                             shadowMaxOpasity: CGFloat) {
        
        let shadowScollOpasity = (contentOffset.y - shadowApplyBeginOffset)/shadowApplyIntensity
        let opasity = min(shadowMaxOpasity, max(0,shadowScollOpasity))
        self.shadowOpacity = opasity
    }
    
    func setText(_ text: String,
                 font: UIFont = .preferredFont(forTextStyle: .body ),
                 insets: UIEdgeInsets? = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)){
        
        titleLabel?.font = font
        contentEdgeInsets = insets ?? .zero
        sizeToFit()
    }
}
