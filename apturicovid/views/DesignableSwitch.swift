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
    
    private var _thumbCornerRadius: CGFloat = 0.5 {
        didSet { layoutSubviews() }
    }
    
    private var _cornerRadius: CGFloat = 0.5 {
        didSet { layoutSubviews() }
    }
    
    var labelOff = UILabel()
    var labelOn = UILabel()
    
    var areLabelsShown: Bool = false {
        didSet { setupUI() }
    }
    var thumbView = DeisgnableThumbView(frame: .zero)
    var onPoint = CGPoint.zero
    var offPoint = CGPoint.zero
    var isAnimating = false
    
    var animationDelay: Double = 0
    var animationSpriteWithDamping = CGFloat(0.7)
    var animationDuration: Double = 0.5
    var initialSpringVelocity = CGFloat(0.5)
    
    var animationOptions: UIView.AnimationOptions = [
        .curveEaseOut,
        .beginFromCurrentState,
        .allowUserInteraction
    ]
    
    //MARK: Touch Properties
    fileprivate lazy var touchStartValue = isOn
    fileprivate var touchEndValue: Bool { isOn }
    fileprivate var valueDidSwitchDuringCurrentTouchEvent = false
    fileprivate var touchEventIsActive = false {
        didSet {
            if touchEventIsActive {
                valueDidSwitchDuringCurrentTouchEvent = false
                touchStartValue = isOn
            }
        }
    }
    
    //MARK: On/Off switch
    @IBInspectable var isOn: Bool {
        get { _isOn }
        set { setOn(newValue, animated: false) }
    }
    
    private var _isOn: Bool = true {
        didSet {
            if oldValue != isOn {
                valueDidSwitchDuringCurrentTouchEvent = true
            }
        }
    }
    
    func setOn(_ on: Bool, animated: Bool) {
        
        guard _isOn != on else { return }
        
        if animated {
            animateTransitionToState(isOn: on)
        } else {
            self._isOn = on
            setupViewsOnAction()
            completeAction()
        }
    }
    
    //MARK: Designables
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
    
    //MARK: Thumb properties
    @IBInspectable public var thumbTintColor: UIColor = .white {
        didSet { thumbView.backgroundColor = thumbTintColor }
    }
    
    @IBInspectable public var thumbCornerRadius: CGFloat {
        get { _thumbCornerRadius }
        set {
            let alowedRange: ClosedRange<CGFloat> = 0...0.5
            guard !(alowedRange ~= newValue) else {
                _thumbCornerRadius = 0.5
                return
            }
            _thumbCornerRadius = newValue
        }
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
    
    
    //MARK: Init:
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
    
    func startTouchEvent(){
        touchEventIsActive = true
    }
    
    func finishTouchEvent(){
        if touchStartValue != touchEndValue {
            sendActions(for: .valueChanged)
        }
        touchEventIsActive = false
    }
    
    override open func beginTracking(_ touch: UITouch,
                                     with event: UIEvent?) -> Bool{
        startTouchEvent()
        calculateIsOn(from: touch)
        return shouldContinueTracking(for: touch)
    }
    
    override open func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        calculateIsOn(from: touch)
        return shouldContinueTracking(for: touch)
    }
    
    override open func endTracking(_ touch: UITouch?, with event: UIEvent?) {
 
        if !valueDidSwitchDuringCurrentTouchEvent { // Handle as tap event
            setOnWithFeedback(!isOn)
        } else {
            calculateIsOn(from: touch)
        }
        
        finishTouchEvent()
        super.endTracking(touch, with: event)
    }
    
    private func calculateIsOn(from touch: UITouch?){
        
        let sensetivityTreshhold = bounds.width / 2
        let sensetivityDeadzoneX: ClosedRange<CGFloat> = bounds.midX - sensetivityTreshhold/2 ... bounds.midX + sensetivityTreshhold/2
        
        let posX: CGFloat = (touch?.location(in: thumbView) ?? .zero).x
        let shouldBecomeOn = posX > bounds.width/2
        
        guard !(sensetivityDeadzoneX ~= posX) && shouldBecomeOn != isOn else { return }

        setOnWithFeedback(shouldBecomeOn)
    }
    
    private func shouldContinueTracking(for touch: UITouch) -> Bool {
        
        guard !valueDidSwitchDuringCurrentTouchEvent else { return true }
        let shouldContinue = touch.location(in: self).distance(to: bounds.center) < 200
        if !shouldContinue { finishTouchEvent() }
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
        
        addSubview(thumbView)
        
        setupLabels()
    }
    
    
    private func clear() {
        subviews.forEach{ $0 .removeFromSuperview() }
    }
    
    private func setOnWithFeedback(_ on: Bool) {
        setOn(on, animated: true)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    func completeAction(){
        isAnimating = false
    }
    
    fileprivate func animateTransitionToState(isOn: Bool? = nil) {
        
        self._isOn = isOn ?? !self._isOn
        
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
            self?.isAnimating = false
        })
    }
    
    private func setupViewsOnAction() {
        thumbView.frame.origin.x = isOn ? onPoint.x : offPoint.x
        backgroundColor = isOn ? onTintColor : offTintColor
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
