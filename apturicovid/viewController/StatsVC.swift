import UIKit

class StatsVC: BaseViewController {
    @IBOutlet weak var statisticsTitleLabel: UILabel!
    @IBOutlet weak var dataRenewalLabel: UILabel!
    @IBOutlet weak var stat1: UIView!
    @IBOutlet weak var stat2: UIView!
    @IBOutlet weak var stat3: UIView!
    @IBOutlet weak var stat4: UIView!
    
    var statView1: StatView!
    var statView2: StatView!
    var statView3: StatView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        statView1 = StatView().fromNib() as! StatView
        statView2 = StatView().fromNib() as! StatView
        statView3 = StatView().fromNib() as! StatView
        
        stat1.addSubviewWithInsets(statView1)
        stat2.addSubviewWithInsets(statView2)
        stat3.addSubviewWithInsets(statView3)
        
        RestClient.shared.fetchStats()
            .subscribe(onNext: { (stats) in
                guard let stats = stats else { return }
                
                self.statView1.setupView(kind: "tested", overallCount: stats.totalTestsCount, yesterdayCount: stats.yesterdaysTestsCount)
                self.statView2.setupView(kind: "new_cases", overallCount: stats.totalInfectedCount, yesterdayCount: stats.yesterdaysInfectedCount)
                self.statView3.setupView(kind: "deceased", overallCount: stats.totalDeathCount, yesterdayCount: stats.yesterdayDeathCount)
            }, onError: justPrintError)
    }
    
    override func translate() {
        statisticsTitleLabel.text = "latvia_covid_statistics".translated
        dataRenewalLabel.text = String(format: "data_renewed".translated, "12.04.2020.")
    }
}
