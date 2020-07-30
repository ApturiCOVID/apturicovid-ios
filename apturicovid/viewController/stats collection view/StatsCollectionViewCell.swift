import UIKit

//MARK: - ValueField
struct ValueField<T> {
    let valueTitle: String
    let value: T?
}

//MARK: - DoubleValueField
class DoubleValueField<T> {
    let title: String
    let field1: ValueField<T>
    let field2: ValueField<T>
    
    init(title: String, field1: ValueField<T>, field2: ValueField<T>) {
        self.title = title
        self.field1 = field1
        self.field2 = field2
    }
}

//MARK: - StatsCollectionViewCell
class StatsCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var headerViewHeight: NSLayoutConstraint!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var field1TitleLabel: UILabel!
    @IBOutlet weak var field1ValueLabel: UILabel!
    @IBOutlet weak var field2TitleLabel: UILabel!
    @IBOutlet weak var field2ValueLabel: UILabel!
    
    static var identifier: String { String(describing: self) }
    
    var stat: DoubleValueField<Int>!
    
    override func prepareForReuse() {
        [
            titleLabel,
            field1TitleLabel,
            field1ValueLabel,
            field2TitleLabel,
            field2ValueLabel
        ].forEach{ $0?.text = nil }
    }
    
    func setupData(with field: DoubleValueField<Int>){
        
        self.titleLabel.text = field.title
        
        self.field1TitleLabel.text = field.field1.valueTitle
        if let value = field.field1.value {
            self.field1ValueLabel.text = "\(value)"
        } else {
            self.field1ValueLabel.text = "-"
        }
        
        self.field2TitleLabel.text = field.field2.valueTitle
        if let value = field.field2.value {
            self.field2ValueLabel.text = "\(value)"
        } else if field.field2.valueTitle == "" {
            self.field2ValueLabel.text = ""
        } else {
            self.field2ValueLabel.text = "-"
        }
        
        let labelSize = titleLabel.sizeThatFits(CGSize(width: frame.width, height: frame.height))
        headerViewHeight.constant = max(40, labelSize.height + 16)
    }
}
