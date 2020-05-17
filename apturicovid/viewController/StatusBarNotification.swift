import UIKit

class StatusBarNotification: SlideViewController {
    @IBOutlet weak var errorLabel: UILabel!
    
    var text: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        errorLabel.text = text
    }
    
    @IBAction func onErrorCloseTap(_ sender: Any) {
        closeView(direction: .top)
    }
}
