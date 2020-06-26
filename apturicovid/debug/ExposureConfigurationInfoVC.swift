import UIKit
import RxSwift

class ExposureConfigurationInfoVC: BaseViewController {
    @IBOutlet weak var infoView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ExposuresClient.shared.getExposuresConfiguration()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (configuration) in
                self.infoView.text = configuration.debugDescription
            }, onError: justPrintError)
            .disposed(by: disposeBag)
    }
}
