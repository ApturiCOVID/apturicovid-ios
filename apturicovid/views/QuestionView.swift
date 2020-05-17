import UIKit
import RxGesture
import RxSwift
import Anchorage

class QuestionView: UIView {
    let stackView = UIStackView()
    
    let messageLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        return label
    }()
    
    let descriptionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = Colors.mainDark
        label.font = UIFont.systemFont(ofSize: 16, weight: .light)
        return label
    }()
    
    let expandImage: UIImageView = {
        let image = UIImageView()
        image.image = UIImage(named: "expand-image")
        image.contentMode = .scaleAspectFit
        return image
    }()
    
    let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "#F2F3F0")
        return view
    }()
    
    let titleRow = UIView()
    let descriptionHolder = UIView()
    
    var descriptionVisible = false {
        didSet {
            setupExpandedVisuals()
        }
    }
    
    var labelTouchDisposable: Disposable?
    
    func fillWith(faq: FAQ) {
        messageLabel.text = faq.title
        descriptionLabel.text = faq.description
    }
    
    init() {
        super.init(frame: .zero)
        
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setup()
    }
    
    private func setupExpandedVisuals() {
        let imageAngle: CGFloat = descriptionVisible ? 90.0 : -90.0
        descriptionHolder.isHidden = !descriptionVisible
        messageLabel.textColor = descriptionVisible ? Colors.mintGreen : Colors.mainDark
        
        UIView.animate(withDuration: 0.2) {
            self.expandImage.rotate(angle: imageAngle)
        }
    }
    
    private func setup() {
        stackView.axis = .vertical
        
        addSubview(separatorView) {
            $0.topAnchor == $1.topAnchor
            $0.leftAnchor == $1.leftAnchor + 30
            $0.rightAnchor == $1.rightAnchor - 30
            $0.heightAnchor == 2
        }
        
        addSubview(stackView) {
            $0.topAnchor == separatorView.bottomAnchor
            $0.leftAnchor == $1.leftAnchor
            $0.rightAnchor == $1.rightAnchor
            $0.bottomAnchor == $1.bottomAnchor
        }
        
        stackView.addArrangedSubview(titleRow)
        
        titleRow.addSubview(messageLabel) {
            $0.topAnchor == $1.topAnchor + 15
            $0.bottomAnchor == $1.bottomAnchor - 15
            $0.leftAnchor == $1.leftAnchor + 30
        }
        
        titleRow.addSubview(expandImage) {
            $0.rightAnchor == $1.rightAnchor - 30
            $0.centerYAnchor == $1.centerYAnchor
            $0.leftAnchor == messageLabel.rightAnchor
            $0.widthAnchor == 15
            $0.heightAnchor == 15
        }
        
        descriptionHolder.addSubviewWithInsets(descriptionLabel, insets: UIEdgeInsets(top: 10, left: 30, bottom: 20, right: 30))
        stackView.addArrangedSubview(descriptionHolder)
        
        expandImage.rotate(angle: -90)
        
        descriptionHolder.isHidden = true
        
        labelTouchDisposable = titleRow
            .rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { (_) in
                self.descriptionVisible = !self.descriptionVisible
            }, onError: justPrintError)
    }
}
