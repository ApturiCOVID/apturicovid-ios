import UIKit
import Anchorage

class LanguageStack: UIView {
    let stackView: UIStackView = {
        let stack = UIStackView()
        stack.spacing = 10
        return stack
    }()
    
    let langViews = Language.allCases.map{ LanguageView.create($0) }
    
    private override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func setupLanguageSelector(){
        langViews.forEach { langView in
            
            langView.isSelected = langView.language.isPrimary
            stackView.addArrangedSubview(langView)
            
            langView.widthAnchor == stackView.heightAnchor
            langView.heightAnchor == stackView.heightAnchor
           
            langView.onSelected() { [weak self] selected in
                guard selected else { return }
                Language.primary = langView.language
                self?.langViews
                    .filter{ $0.language != langView.language }
                    .forEach{ $0.isSelected = false }
            }
        }
    }
    
    private func commonInit() {
        addSubviewWithInsets(stackView)
        setupLanguageSelector()
    }
}
