import UIKit

//MARK: - ValueField
struct ValueField<T> {
    let valueTitle: String
    let value: T?
}

//MARK: - DoubleValueField
class DoubleValueField<T> {
    let title: String
    let fieldTotal: ValueField<T>
    let fieldYesterday: ValueField<T>
    
    init(title: String, fieldTotal: ValueField<T>, fieldYesterday: ValueField<T>) {
        self.title = title
        self.fieldTotal = fieldTotal
        self.fieldYesterday = fieldYesterday
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
    
    func setupData(with data: DoubleValueField<Int>){
        
        self.titleLabel.text = data.title
        
        self.field1TitleLabel.text = data.fieldTotal.valueTitle
        if let value = data.fieldTotal.value {
            self.field1ValueLabel.text = "\(value)"
        } else {
            self.field1ValueLabel.text = "-"
        }
        
        self.field2TitleLabel.text = data.fieldYesterday.valueTitle
        if let value = data.fieldYesterday.value {
            self.field2ValueLabel.text = "\(value)"
        } else if data.fieldYesterday.valueTitle == "" {
            self.field2ValueLabel.text = ""
        } else {
            self.field2ValueLabel.text = "-"
        }
        
        let labelSize = titleLabel.sizeThatFits(CGSize(width: frame.width, height: frame.height))
        headerViewHeight.constant = max(40, labelSize.height + 16)
    }
}
