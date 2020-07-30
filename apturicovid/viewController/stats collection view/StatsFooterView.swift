import UIKit

//MARK: - StatsHeaderView
class StatsFooterView: UICollectionReusableView {

    @IBOutlet weak var linkButton: AutoLayoutButton!
    
    @IBAction func linkTap(_ sender: Any) {
        openUrlLink()
    }
    
    static var identifier: String { String(describing: self) }
    var linkUrl: URL?
    
    override func prepareForReuse() {
        linkButton.setTitle(nil, for: .normal)
        linkUrl = nil
    }
    
    func setup(with text: String, linkUrl: URL){
        linkButton.setTitle(text, for: .normal)
        self.linkUrl = linkUrl
    }
    
    private func openUrlLink(){
        
        guard let url = linkUrl else { return }
        
        if UIApplication.shared.canOpenURL(url){
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}
