import UIKit

class CheckboxView: UIView {
    
    @IBOutlet weak var bodyLabel: UILabel!
    
    var text: String? {
        get{ bodyLabel.text }
        set{ bodyLabel.text = newValue }
    }
    
    class func create(text: String, isSelected: Bool = false) -> CheckboxView {
        let view: CheckboxView = CheckboxView().fromNib() as! CheckboxView
        view.bodyLabel.text = text
        return view
    }
    
    private override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit(){
        let tapRecogniser = UITapGestureRecognizer(target: self, action: #selector(invokeAction))
        self.addGestureRecognizer(tapRecogniser)
    }
    
    @objc func invokeAction(){
        //TODO: toggle checkbox
    }
    
}
