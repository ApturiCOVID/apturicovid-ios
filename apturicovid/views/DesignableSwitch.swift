//
//  ExposureSwitch.swift
//  apturicovid
//
//  Created by Artjoms Spole on 25/05/2020.
//  Copyright © 2020 MAK IT. All rights reserved.
//
import UIKit

@IBDesignable
public class DesignableSwitch: UIControl {
    
    //MARK: Touch Properties
    fileprivate lazy var touchStartState = isOn
    fileprivate var valueDidChangeDuringTouchEvent = false
    fileprivate var touchEndState: Bool { isOn }
    fileprivate var touchEventIsActive = false {
        didSet { if touchEventIsActive { touchStartState = isOn } }
    }

    // MARK: Public properties
    public var animationDelay: Double = 0
    public var animationSpriteWithDamping = CGFloat(0.7)
    public var animationDuration: Double = 0.5
    public var initialSpringVelocity = CGFloat(0.5)
    
    public var animationOptions: UIView.AnimationOptions = [
        .curveEaseOut,
        .beginFromCurrentState,
        .allowUserInteraction
    ]
    
    @IBInspectable private (set) var isOn: Bool = true {
        didSet {
            if oldValue != isOn {
                valueDidChangeDuringTouchEvent = touchEventIsActive
            }
        }
    }
    
    @IBInspectable public var padding: CGFloat = 1 {
        didSet { layoutSubviews() }
    }
    
    @IBInspectable public var onTintColor: UIColor = .green {
        didSet { setupUI() }
    }
    
    @IBInspectable public var offTintColor: UIColor = .black {
        didSet { setupUI() }
    }
    
    @IBInspectable public var cornerRadius: CGFloat {
        get { _cornerRadius }
        set { _cornerRadius = max(0, min(0.5, newValue) ) } // 0..0.5
    }

    private var _cornerRadius: CGFloat = 0.5 {
        didSet { layoutSubviews() }
    }
    
    //MARK: Thumb properties
    @IBInspectable public var thumbTintColor: UIColor = .white {
        didSet { thumbView.backgroundColor = thumbTintColor }
    }
    
    @IBInspectable public var thumbCornerRadius: CGFloat {
        get {
            return _thumbCornerRadius
        }
        set {
            if newValue > 0.5 || newValue < 0.0 {
                _thumbCornerRadius = 0.5
            } else {
                _thumbCornerRadius = newValue
            }
        }
        
    }
    
    private var _thumbCornerRadius: CGFloat = 0.5 {
        didSet { layoutSubviews() }
    }
    
    @IBInspectable public var thumbSize: CGSize = CGSize.zero {
        didSet { layoutSubviews() }
    }
    
    @IBInspectable public var thumbImage: UIImage? = nil {
        didSet {
            guard let image = thumbImage else { return }
            thumbView.thumbImageView.image = image
        }
    }
    
    public var onImage: UIImage? {
        didSet {
            onImageView.image = onImage
            layoutSubviews()
        }
    }
    
    public var offImage: UIImage? {
        didSet {
            offImageView.image = offImage
            layoutSubviews()
        }
    }
    
    @IBInspectable public var thumbShadowColor: UIColor = .black {
        didSet { thumbView.layer.shadowColor = thumbShadowColor.cgColor }
    }
    
    @IBInspectable public var thumbShadowOffset: CGSize = CGSize(width: 0.75, height: 2) {
        didSet { thumbView.layer.shadowOffset = thumbShadowOffset }
    }
    
    @IBInspectable public var thumbShaddowRadius: CGFloat = 1.5 {
        didSet { thumbView.layer.shadowRadius = thumbShaddowRadius }
    }
    
    @IBInspectable public var thumbShaddowOppacity: Float = 0.4 {
        didSet { thumbView.layer.shadowOpacity = thumbShaddowOppacity }
    }
    
    //MARK: Labels
    public var labelOff = UILabel()
    public var labelOn = UILabel()
    
    public var areLabelsShown: Bool = false {
        didSet { setupUI() }
    }
    
    var thumbView = DeisgnableThumbView(frame: .zero)
    
    public var onImageView = UIImageView(frame: .zero)
    public var offImageView = UIImageView(frame: .zero)
    public var onPoint = CGPoint.zero
    public var offPoint = CGPoint.zero
    public var isAnimating = false
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
}

//MARK: TouchEvents:
extension DesignableSwitch {
   
       override open func beginTracking(_ touch: UITouch,
                                        with event: UIEvent?) -> Bool{
           touchEventIsActive = true
           setIsOn(from: touch)
           return  shouldContinueTracking(for: touch)
       }
       
       override open func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
           setIsOn(from: touch)
           return shouldContinueTracking(for: touch)
       }
       
    override open func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        print("end tracking")
        
        if !valueDidChangeDuringTouchEvent {
            setOn(!isOn, animated: true)
        } else {
            setIsOn(from: touch)
        }
        
        touchEventIsActive = false
        completeAction(withTouch: true)
       
        super.endTracking(touch, with: event)
    }
    
    private func setIsOn(from touch: UITouch?){
        
        let sensetivityTreshhold = bounds.width / 2
        let sensetivityDeadzoneX: ClosedRange<CGFloat> = bounds.midX - sensetivityTreshhold/2 ... bounds.midX + sensetivityTreshhold/2
        
        let posX: CGFloat = (touch?.location(in: thumbView) ?? .zero).x
        let shouldBecomeOn = posX > bounds.width/2
        
        guard !(sensetivityDeadzoneX ~= posX) && shouldBecomeOn != isOn else { return }

        setOnWithFeedback(shouldBecomeOn)
    }
    
    private func shouldContinueTracking(for touch: UITouch) -> Bool {
        let shouldContinue = touch.location(in: self).distance(to: bounds.center) < (valueDidChangeDuringTouchEvent ? 300 : 150)
        if !shouldContinue {
            touchEventIsActive = false
            completeAction(withTouch: true)
        }
        return shouldContinue
    }
}

// MARK: Private methods
extension DesignableSwitch {
    fileprivate func setupUI() {
        
        clear()
        
        clipsToBounds = false

        thumbView.backgroundColor = thumbTintColor
        thumbView.isUserInteractionEnabled = false
        thumbView.layer.shadowColor = thumbShadowColor.cgColor
        thumbView.layer.shadowRadius = thumbShaddowRadius
        thumbView.layer.shadowOpacity = thumbShaddowOppacity
        thumbView.layer.shadowOffset = thumbShadowOffset
        
        backgroundColor = isOn ? onTintColor : offTintColor
        
        addSubview(self.thumbView)
        addSubview(self.onImageView)
        addSubview(self.offImageView)
        
        setupLabels()
    }
    
    
    private func clear() {
        subviews.forEach{ $0 .removeFromSuperview() }
    }
    
    private func setOnWithFeedback(_ on: Bool) {
        setOn(on, animated: true)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    func setOn(_ on: Bool, animated: Bool) {
        
        guard isOn != on else { return }
        
        if animated {
            animate(isOn: on)
        } else {
            self.isOn = on
            setupViewsOnAction()
            completeAction()
        }
    }
    
    fileprivate func animate(isOn: Bool? = nil) {
        
        self.isOn = isOn ?? !self.isOn
        
        isAnimating = true
        
        UIView.animate(withDuration: animationDuration,
                       delay: 0,
                       usingSpringWithDamping: 0.7,
                       initialSpringVelocity: 0.5,
                       options: [UIView.AnimationOptions.curveEaseOut,
                                 UIView.AnimationOptions.beginFromCurrentState,
                                 UIView.AnimationOptions.allowUserInteraction],
                       animations: {
                        self.setupViewsOnAction()
                        
        }, completion: { [weak self] _ in
            self?.completeAction()
        })
    }
    
    private func setupViewsOnAction() {
        thumbView.frame.origin.x = isOn ? onPoint.x : offPoint.x
        backgroundColor = isOn ? onTintColor : offTintColor
        setOnOffImageFrame()
    }

    private func completeAction(withTouch: Bool = false) {
        isAnimating = false
        if !touchEventIsActive {
            if withTouch {
                if touchStartState != touchEndState {
                    sendActions(for: .valueChanged)
                }
            } else {
                 //sendActions(for: .valueChanged)
            }
            
            
        }
    }
    
}

//MARK: Public methods
extension DesignableSwitch {
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        if !isAnimating {
            layer.cornerRadius = bounds.size.height * cornerRadius
            backgroundColor = isOn ? onTintColor : offTintColor
            
            // thumb managment
            // get thumb size, if none set, use one from bounds
            let thumbSize = self.thumbSize != .zero ?
                self.thumbSize : CGSize(width: bounds.size.height - 2, height: bounds.height - 2)
            
            let yPostition = (bounds.size.height - thumbSize.height) / 2
            
            onPoint = CGPoint(x: bounds.size.width - thumbSize.width - padding, y: yPostition)
            offPoint = CGPoint(x: padding, y: yPostition)
            
            thumbView.frame = CGRect(origin: isOn ? onPoint : offPoint, size: thumbSize)
            thumbView.layer.cornerRadius = thumbSize.height * thumbCornerRadius
            
            
            //label frame
            if areLabelsShown {
                let labelWidth = bounds.width / 2 - padding * 2
                labelOn.frame = CGRect(x: 0, y: 0, width: labelWidth, height: frame.height)
                labelOff.frame = CGRect(x: frame.width - labelWidth, y: 0, width: labelWidth, height: frame.height)
            }
            
            // on/off images
            //set to preserve aspect ratio of image in thumbView
            
            guard onImage != nil && offImage != nil else { return }
            
            let frameSize = thumbSize.width > thumbSize.height ? thumbSize.height * 0.7 : thumbSize.width * 0.7
            
            let onOffImageSize = CGSize(width: frameSize, height: frameSize)
            
            
            onImageView.frame.size = onOffImageSize
            offImageView.frame.size = onOffImageSize
            
            onImageView.center = CGPoint(x: onPoint.x + thumbView.frame.size.width / 2,
                                         y: thumbView.center.y)
            
            offImageView.center = CGPoint(x: offPoint.x + thumbView.frame.size.width / 2,
                                          y: thumbView.center.y)
            
            
            onImageView.alpha = isOn ? 1.0 : 0.0
            offImageView.alpha = isOn ? 0.0 : 1.0
            
        }
    }
}

//MARK: Labels frame
extension DesignableSwitch {
    
    fileprivate func setupLabels() {
        guard areLabelsShown else {
            labelOff.alpha = 0
            labelOn.alpha = 0
            return
            
        }
        
        labelOff.alpha = 1
        labelOn.alpha = 1
        
        let labelWidth = bounds.width / 2 - padding * 2
        labelOn.frame = CGRect(x: 0, y: 0, width: labelWidth, height: frame.height)
        labelOff.frame = CGRect(x: frame.width - labelWidth, y: 0, width: labelWidth, height: frame.height)
        labelOn.font = UIFont.boldSystemFont(ofSize: 12)
        labelOff.font = UIFont.boldSystemFont(ofSize: 12)
        labelOn.textColor = UIColor.white
        labelOff.textColor = UIColor.white
        
        labelOff.sizeToFit()
        labelOff.text = "Off"
        labelOn.text = "On"
        labelOff.textAlignment = .center
        labelOn.textAlignment = .center
        
        insertSubview(labelOff, belowSubview: thumbView)
        insertSubview(labelOn, belowSubview: thumbView)
        
    }
    
}

//MARK: Animating on/off images
extension DesignableSwitch {
    
    fileprivate func setOnOffImageFrame() {
        
        guard onImage != nil && offImage != nil else { return }
        
        onImageView.center.x = isOn ? onPoint.x + thumbView.frame.size.width / 2 : frame.width
        offImageView.center.x = isOn ? 0 : offPoint.x + thumbView.frame.size.width / 2
        onImageView.alpha = isOn ? 1.0 : 0.0
        offImageView.alpha = isOn ? 0.0 : 1.0
    }
}

final class DeisgnableThumbView: UIView {
    
    private(set) var thumbImageView = UIImageView(frame: .zero)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(thumbImageView)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addSubview(thumbImageView)
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        thumbImageView.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        thumbImageView.layer.cornerRadius = layer.cornerRadius
        thumbImageView.clipsToBounds = clipsToBounds
    }

}



