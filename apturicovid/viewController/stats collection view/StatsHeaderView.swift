import UIKit

//MARK: - HeaderValueField
struct HeaderValueField {
    let title: String
    let description: String
}

//MARK: - StatsHeaderView
class StatsHeaderView: UICollectionReusableView {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    var urlLink: String?
    
    static var identifier: String { String(describing: self) }
    
    override func prepareForReuse() {
        titleLabel.text = nil
        descriptionLabel.text = nil
    }
    
    func setupData(with field: HeaderValueField){
        titleLabel.text = field.title
        descriptionLabel.text = field.description
    }
}
