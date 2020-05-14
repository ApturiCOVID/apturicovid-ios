import UIKit

//MARK: - CheckboxView
class CheckboxView: UIView {
    
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var checkBox: CheckBox!
    
    var text: String? {
        get{ bodyLabel.text }
        set{ bodyLabel.text = newValue }
    }
    
    var isChecked: Bool {
        get{ checkBox.isChecked }
        set{ checkBox.isChecked = newValue }
    }
    
    class func create(text: String, isChecked: Bool = false) -> CheckboxView {
        let view: CheckboxView = CheckboxView().fromNib() as! CheckboxView
        view.bodyLabel.text = text
        view.checkBox.isChecked = isChecked
        return view
    }
    
}

//MARK: - CheckBox
class CheckBox: UIButton {

    private let checkedImage = UIImage(named: "checkbox-checked")
    private let uncheckedImage = UIImage(named: "checkbox")

    var isChecked: Bool = false {
        didSet {
            self.setImage( isChecked ? checkedImage : uncheckedImage, for: .normal)
        }
    }

    override func awakeFromNib() {
        self.addTarget(self, action:#selector(buttonClicked(sender:)), for: UIControl.Event.touchUpInside)
        self.isChecked = false
    }

    @objc func buttonClicked(sender: UIButton) {
        if sender == self {
            isChecked = !isChecked
        }
    }
}
