//
//  LunkLabel.swift
//  apturicovid
//
//  Created by Artjoms Spole on 14/05/2020.
//  Copyright © 2020 MAK IT. All rights reserved.
//

import UIKit

//MARK: - LinkLabelDelegate
public protocol LinkLabelDelegate: NSObjectProtocol {
    func linkLabel(_ label: LinkLabel, didTapUrl url: String, atRange range: NSRange)
}

//MARK: - LinkLabel
public class LinkLabel: UILabel {
    
    private struct TextLink: Equatable {
        let link: String
        let range: NSRange
    }
    
    weak var delegate: LinkLabelDelegate?
    
    private var touchStartLink: TextLink?
    private var links = [TextLink]()
    private var activeLinkOriginalColor: UIColor?
    
    private(set) var layoutManager = NSLayoutManager()
    private(set) var textContainer = NSTextContainer(size: CGSize.zero)
    private(set) var textStorage = NSTextStorage() {
        didSet { textStorage.addLayoutManager(layoutManager) }
    }
    
    public override var attributedText: NSAttributedString? {
        didSet {
            if let attributedText = attributedText {
                textStorage = NSTextStorage(attributedString: attributedText)
                links = getLinks(from: attributedText)
            } else {
                textStorage = NSTextStorage()
                links.removeAll()
            }
        }
    }

    public override var lineBreakMode: NSLineBreakMode {
        didSet { textContainer.lineBreakMode = lineBreakMode }
    }

    public override var numberOfLines: Int {
        didSet { textContainer.maximumNumberOfLines = numberOfLines }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        isUserInteractionEnabled = true
        layoutManager.addTextContainer(textContainer)
        textContainer.lineFragmentPadding = 0
        textContainer.lineBreakMode = lineBreakMode
        textContainer.maximumNumberOfLines  = numberOfLines
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        textContainer.size = bounds.size
    }

    private func getLinks(from attributeString: NSAttributedString) -> [TextLink] {
        
        typealias EnumerationBlock = (Any?, NSRange, UnsafeMutablePointer<ObjCBool>) -> Void
        
        func enumerate(with key: NSAttributedString.Key, using block: EnumerationBlock ){
            attributeString.enumerateAttribute(key,
                                               in: NSRange(0..<attributeString.length),
                                               options: [.longestEffectiveRangeNotRequired],
                                               using: block)
        }
        
        var links = [TextLink]()
        
         // Find links
        let linkEnumerationBlock: EnumerationBlock = { value, range, _ in
            if let value = value {
                links.append(TextLink(link: "\(value)", range: range))
            }
        }
        
        // Find link color attributes
        let colorEnumerationBlock: EnumerationBlock = { [weak self] value, _, _ in
            if self?.activeLinkOriginalColor == nil {
                self?.activeLinkOriginalColor = value as? UIColor
            }
        }
        
        enumerate(with: .link, using: linkEnumerationBlock)
        enumerate(with: .attachment, using: linkEnumerationBlock)
        enumerate(with: .foregroundColor, using: colorEnumerationBlock)
       
        return links
    }
    
    private func setLinkHovered(_ link: TextLink?, hovered: Bool){
        guard let attributedText = attributedText, let link = link else { return }
        
        let color: UIColor = {
            let defaultColor = activeLinkOriginalColor ?? .darkGray
            let hoverColor = defaultColor.withAlphaComponent(0.7)
            return hovered ? hoverColor : defaultColor
        }()
        
        let mutableText = NSMutableAttributedString(attributedString: attributedText)
        
        let attributes: NSStringAttributes = [
            .foregroundColor : color,
            .underlineColor : color
        ]
        
        mutableText.addAttributes(attributes, range: link.range)
        
        self.attributedText = mutableText
    }
    
    private func linkAt(_ touches: Set<UITouch>) -> TextLink? {
        guard let location = touches.first?.location(in: self), bounds.contains(location) else { return nil}
        textContainer.size = bounds.size
        let indexOfCharacter = layoutManager.glyphIndex(for: location, in: textContainer)
        return links.first(where: { NSLocationInRange(indexOfCharacter, $0.range) })
    }

    //MARK: Touch events:
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchStartLink = linkAt(touches)
        setLinkHovered(touchStartLink, hovered: true)
    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        setLinkHovered(touchStartLink, hovered: touchStartLink == linkAt(touches))
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        defer {
            setLinkHovered(touchStartLink, hovered: false)
            touchStartLink = nil
        }
        
        if let activeLink = touchStartLink, activeLink == linkAt(touches) {
            delegate?.linkLabel(self, didTapUrl: activeLink.link, atRange: activeLink.range)
        }
    }
    
    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        setLinkHovered(touchStartLink, hovered: false)
        touchStartLink = nil
    }
}
