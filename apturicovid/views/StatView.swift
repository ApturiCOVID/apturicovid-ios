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
        kindLabel.text = kind.translated
        overallValueLabel.text = "\(overallCount)"
        yesterdayValueLabel.text = "\(yesterdayCount)"
    }
}
