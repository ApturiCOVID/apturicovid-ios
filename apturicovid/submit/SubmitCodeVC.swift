import UIKit
import RxCocoa
import RxSwift
import RxGesture

class SubmitCodeVC: UIViewController {
    @IBOutlet weak var scrollViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scrollContainerView: UIView!
    @IBOutlet weak var codeInputField: EntryView!
    @IBOutlet weak var enterCodeButton: UIButton!
    
    private var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.rx
            .notification(UIResponder.keyboardWillShowNotification)
            .subscribe(onNext: { [weak self] notification in
                guard
                    let self = self,
                    let keyboardFrame: CGRect = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
                    else { return }
                
                self.scrollViewBottomConstraint.constant = keyboardFrame.height
                
                self.scrollView.scrollRectToVisible(self.enterCodeButton.bounds, animated: true)
            }, onError: justPrintError)
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx
            .notification(UIResponder.keyboardDidHideNotification)
            .subscribe(onNext: { [weak self] (_) in
                self?.scrollViewBottomConstraint.constant = 0
            }, onError: justPrintError)
            .disposed(by: disposeBag)
        
        scrollContainerView.rx.tapGesture()
            .when(.recognized).subscribe(onNext: { [weak self] _ in
                _ = self?.codeInputField.resignFirstResponder()
            }, onError: justPrintError)
            .disposed(by: disposeBag)
    }
}
