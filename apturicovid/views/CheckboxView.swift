import UIKit

class CheckboxView: UIView {
    
    @IBOutlet weak var bodyLabel: UILabel!
    
    class func create(text: String, isSelected: Bool = false) -> CheckboxView {
        let view: CheckboxView = CheckboxView().fromNib() as! CheckboxView
        view.bodyLabel.text = text
        return view
    }
    
    private override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
}
