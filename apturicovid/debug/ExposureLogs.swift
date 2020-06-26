import UIKit

class ExposureLogs: UIViewController {
    @IBOutlet var exposureLogs: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let logs = try? JSONEncoder().encode(LocalStore.shared.exposures) else {
            return
        }
        
        exposureLogs.text = String(data: logs, encoding: .utf8)
    }
}
