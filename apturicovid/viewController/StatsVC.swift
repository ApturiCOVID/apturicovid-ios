import UIKit

class StatsVC: BaseViewController {
    @IBOutlet weak var stat1: UIView!
    @IBOutlet weak var stat2: UIView!
    @IBOutlet weak var stat3: UIView!
    @IBOutlet weak var stat4: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let statView1 = StatView().fromNib() as! StatView
        let statView2 = StatView().fromNib() as! StatView
        let statView3 = StatView().fromNib() as! StatView
        let statView4 = StatView().fromNib() as! StatView
        
        stat1.addSubviewWithInsets(statView1)
        stat2.addSubviewWithInsets(statView2)
        stat3.addSubviewWithInsets(statView3)
        stat4.addSubviewWithInsets(statView4)
    }
}
