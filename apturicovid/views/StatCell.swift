import UIKit

class StatCell: UIView {
    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var itemName: UILabel!
    
    class func create(item: String = "", value: Int? = nil) -> StatCell {
        let view: StatCell = StatCell().fromNib() as! StatCell
        view.updateTitle(item)
        view.updateValue(value)
        return view
    }
    
    func updateTitle(_ title: String){
        itemName.text = title
    }
    
    func updateValue(_ value: Int?){
        if let value = value {
            numberLabel.text = "\(value)"
        } else {
            numberLabel.text = "-"
        }
    }
}
