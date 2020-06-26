import UIKit

class StatView: UIView {
    @IBOutlet weak var kindLabel: UILabel!
    @IBOutlet weak var overallLabel: UILabel!
    @IBOutlet weak var yesterdayLabel: UILabel!
    @IBOutlet weak var overallValueLabel: UILabel!
    @IBOutlet weak var yesterdayValueLabel: UILabel!
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        layer.cornerRadius = 10
        clipsToBounds = true
        translate()
    }
    
    private func translate() {
        overallLabel.text = "together".translated
        yesterdayLabel.text = "yesterday".translated
    }
    
    func setupView(kind: String, overallCount: Int, yesterdayCount: Int) {
        DispatchQueue.main.async {
            self.kindLabel.text = kind.translated
            self.overallValueLabel.text = "\(overallCount)"
            self.yesterdayValueLabel.text = "\(yesterdayCount)"
        }
    }
}
