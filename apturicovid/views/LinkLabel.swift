//
//  LunkLabel.swift
//  apturicovid
//
//  Created by Artjoms Spole on 14/05/2020.
//  Copyright © 2020 MAK IT. All rights reserved.
//

import UIKit

public protocol LinkLabelDelegate: NSObjectProtocol {
    func linkLabel(_ label: LinkLabel, didTapUrl url: String, atRange range: NSRange)
}

public class LinkLabel: UILabel {

    private var links: [String: NSRange] = [:]
    private(set) var layoutManager = NSLayoutManager()
    private(set) var textContainer = NSTextContainer(size: CGSize.zero)
    private(set) var textStorage = NSTextStorage() {
        didSet {
            textStorage.addLayoutManager(layoutManager)
        }
    }

    weak var delegate: LinkLabelDelegate?

    public override var attributedText: NSAttributedString? {
        didSet {
            if let attributedText = attributedText {
                textStorage = NSTextStorage(attributedString: attributedText)
                findLinksAndRange(attributeString: attributedText)
            } else {
                textStorage = NSTextStorage()
                links = [:]
            }
        }
    }

    public override var lineBreakMode: NSLineBreakMode {
        didSet {
            textContainer.lineBreakMode = lineBreakMode
        }
    }

    public override var numberOfLines: Int {
        didSet {
            textContainer.maximumNumberOfLines = numberOfLines
        }
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

    private func findLinksAndRange(attributeString: NSAttributedString) {
        links = [:]
        let enumerationBlock: (Any?, NSRange, UnsafeMutablePointer<ObjCBool>) -> Void = { [weak self] value, range, isStop in
            guard let `self` = self else { return }
            if let value = value {
                let stringValue = "\(value)"
                self.links[stringValue] = range
            }
        }
        attributeString.enumerateAttribute(.link, in: NSRange(0..<attributeString.length), options: [.longestEffectiveRangeNotRequired], using: enumerationBlock)
        
        attributeString.enumerateAttribute(.attachment, in: NSRange(0..<attributeString.length), options: [.longestEffectiveRangeNotRequired], using: enumerationBlock)
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let locationOfTouch = touches.first?.location(in: self) else {
            return
        }
        textContainer.size = bounds.size
        let indexOfCharacter = layoutManager.glyphIndex(for: locationOfTouch, in: textContainer)
        for (urlString, range) in links where NSLocationInRange(indexOfCharacter, range) {
            delegate?.linkLabel(self, didTapUrl: urlString, atRange: range)
            return
        }
    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
}
