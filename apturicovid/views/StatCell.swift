import UIKit

class StatCell: UIView {
    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var itemName: UILabel!
    
    func fill(item: String, value: String) {
        numberLabel.text = value
        itemName.text = item
    }
}
