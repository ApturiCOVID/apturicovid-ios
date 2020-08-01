import UIKit
import SafariServices

//MARK: - StatsHeaderView
class StatsFooterView: UICollectionReusableView {

    @IBOutlet weak var linkButton: AutoLayoutButton!
    
    @IBAction func linkTap(_ sender: Any) {
        openURL()
    }
    
    static var identifier: String { String(describing: self) }
    var openURL: (() -> Void)!
    
    override func prepareForReuse() {
        linkButton.setTitle(nil, for: .normal)
    }
    
    func setup(with text: String, _ openURL: @escaping () -> Void) {
        self.openURL = openURL
    }
}
