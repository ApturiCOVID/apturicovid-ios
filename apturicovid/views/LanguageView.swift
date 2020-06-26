import UIKit

final class LanguageView: UIView {
    
    @IBOutlet weak var languageTextView: UILabel!
    @IBOutlet weak var highlightIndicator: RoundedView!
    
    private var onSelectedListener: ((Bool) -> Void)?
    
    private (set) var language: Language! {
        didSet { setNeedsUpdateUI() }
    }
    
    var isSelected: Bool = false {
        didSet {
            setNeedsUpdateUI()
            onSelectedListener?(isSelected)
        }
    }

    class func create(_ language: Language) -> LanguageView {
        let view: LanguageView = LanguageView().fromNib() as! LanguageView
        view.language = language
        view.isSelected = language.isPrimary
        return view
    }
    
    private override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit(){
        let tapRecogniser = UITapGestureRecognizer(target: self, action: #selector(invokeAction))
        self.addGestureRecognizer(tapRecogniser)
    }
    
    private func setNeedsUpdateUI(){
        highlightIndicator.isHidden = !isSelected
        languageTextView.text = language.rawValue
        languageTextView.textColor = isSelected ?
            UIColor(named: "languageSelector") : UIColor(named: "languageSelectorDisabled")
    }
    
    @objc func invokeAction(){
        isSelected = true
    }

    func onSelected(listener: @escaping (Bool) -> Void) {
        onSelectedListener = listener
    }
    
}

