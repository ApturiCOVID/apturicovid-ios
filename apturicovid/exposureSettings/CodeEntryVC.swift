import UIKit

class CodeEntryVC: UIViewController {
    var codeEntry: EntryView!
    @IBOutlet weak var mainStack: UIStackView!
    
    @IBAction func onSubmitTap(_ sender: Any) {
        let key = DiagnosisKey(keyData: "test".data(using: .utf8)!, rollingStartNumber: 0, rollingPeriod: 0, transmissionRiskLevel: 0)
        
        let uploadBody = DiagnosisUploadRequest(uploadCode: codeEntry.text, diagnosisKeys: [key])
        
        let encoder = JSONEncoder.init()
        guard let data = try? encoder.encode(uploadBody) else { return }
        
        RestClient()
            .post(urlString: "api/v1/diagnosis_keys", body: data)
            .subscribe(onNext: { (data) in
                print(data)
            }, onError: { (err) in
                print(err)
            })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        codeEntry = EntryView()
        mainStack.addArrangedSubview(codeEntry)
        NSLayoutConstraint.activate([codeEntry.heightAnchor.constraint(greaterThanOrEqualToConstant: 40.0)])
        
        
    }
}
