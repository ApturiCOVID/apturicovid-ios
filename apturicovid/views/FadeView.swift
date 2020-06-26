import UIKit
import RxSwift

protocol FadeViewDatasource : class {
    func fadeView(_ fadeView: FadeView, notificationsForMaskEnable enable: Bool ) -> [Notification.Name]
}

extension UIScrollView {
    func adjustContentInset(for fadeView: FadeView){
        contentInset.top += fadeView.topOffset
        contentInset.bottom += fadeView.bottomOffset
    }
}

@IBDesignable class FadeView: UIView {
    
    weak var datasource: FadeViewDatasource? {
        didSet { subscribeToEvents() }
    }
    
    private var maskLayer = CAGradientLayer()
    private var disposeBag = DisposeBag()
    
    private var gradientLocations: [NSNumber] {
        return [
            NSNumber(value: Float(0)),
            NSNumber(value: Float(topOffset / bounds.height)),
            NSNumber(value: 1 - Float( bottomOffset / bounds.height)),
            NSNumber(value: 1)
        ]
    }
    
    @IBInspectable var topOffset: CGFloat = 16 {
         didSet {updateMaskLocations()}
    }
    
    @IBInspectable var bottomOffset: CGFloat = 16 {
        didSet {updateMaskLocations()}
    }
    
    @IBInspectable var applyMask: Bool = true {
        didSet{ updateMaskColors() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    override func layoutSubviews() {
        maskLayer.frame = bounds
        updateMaskLocations()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func updateMaskLocations(){
        maskLayer.locations = gradientLocations
    }
       
    private func updateMaskColors(){
        let enabled = [UIColor.clear,.black,.black,.clear].map{ $0.cgColor }
        let disabled = [UIColor.black,.black,.black,.black].map{ $0.cgColor }
        maskLayer.colors = applyMask ? enabled : disabled
    }
    
    private func commonInit(){
        updateMaskColors()
        updateMaskLocations()
        layer.mask = maskLayer
    }
    
    
    var subscribers = [Disposable]()
    
    private func subscribeToEvents(){
        
        func subscribeOn(_ notification: Notification.Name, applyMask: Bool ){
            
            let subscriber = NotificationCenter.default.rx
                .notification(notification)
                .subscribe(onNext: { [weak self] _ in
                    self?.applyMask = applyMask
                    }, onError: justPrintError)
            
            disposeBag.insert(subscriber)
            subscribers.append(subscriber)
        }
        
        
        subscribers.forEach{ $0.dispose() }
        
        datasource?.fadeView(self, notificationsForMaskEnable: true).forEach{ subscribeOn($0, applyMask: true) }
        datasource?.fadeView(self, notificationsForMaskEnable: false).forEach{ subscribeOn($0, applyMask: false) }
            
        }
}
