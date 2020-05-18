import UIKit

class StatsVC: BaseViewController {
    @IBOutlet weak var statisticsTitleLabel: UILabel!
    @IBOutlet weak var dataRenewalLabel: UILabel!
    @IBOutlet weak var stat1: UIView!
    @IBOutlet weak var stat2: UIView!
    @IBOutlet weak var stat3: UIView!
    @IBOutlet weak var stat4: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let statView1 = StatView().fromNib() as! StatView
        let statView2 = StatView().fromNib() as! StatView
        let statView3 = StatView().fromNib() as! StatView
        
        stat1.addSubviewWithInsets(statView1)
        stat2.addSubviewWithInsets(statView2)
        stat3.addSubviewWithInsets(statView3)
        
        statView1.setupView(kind: "tested", overallCount: 98839, yesterdayCount: 2938)
        statView2.setupView(kind: "new_cases", overallCount: 809, yesterdayCount: 32)
        statView3.setupView(kind: "deceased", overallCount: 14, yesterdayCount: 0)
    }
    
    override func translate() {
        statisticsTitleLabel.text = "latvia_covid_statistics".translated
        dataRenewalLabel.text = String(format: "data_renewed".translated, "12.04.2020.")
    }
}
