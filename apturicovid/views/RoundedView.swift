//
//  RoundedView.swift
//  apturicovid
//
//  Created by Artjoms Spole on 20/05/2020.
//  Copyright © 2020 MAK IT. All rights reserved.
//

import UIKit

@IBDesignable class RoundedView: UIView {
    
    @IBInspectable var cornerRadius: CGFloat = 0.0 {
        didSet {
            layer.cornerRadius = cornerRadius
            layer.masksToBounds = cornerRadius > 0
        }
    }
    
    @IBInspectable var lineWidth: CGFloat = 0.0 {
        didSet { layer.borderWidth = lineWidth }
    }
    
    @IBInspectable var lineColor: UIColor = .black {
        didSet{ layer.borderColor = lineColor.cgColor }
    }
    
    @IBInspectable var shadowRadius  :CGFloat = 0 {
        didSet  { applyShadow(shadowEnabled) }
    }
    
    @IBInspectable var shadowOpacity :Float   = 0.5 {
        didSet  { applyShadow(shadowEnabled) }
    }
    
    @IBInspectable var shadowEnabled :Bool    = false {
        didSet { applyShadow(shadowEnabled) }
    }
    
    @IBInspectable var shadowColor: UIColor = .lightGray {
        didSet{ layer.shadowColor = shadowColor.cgColor }
    }
    
    override func awakeFromNib() {
       // layer.masksToBounds = cornerRadius > 0
    }
    
    private func applyShadow(_ enabled: Bool){
        if enabled{
            layer.shadowRadius  = shadowRadius
            layer.shadowOpacity = shadowOpacity
            layer.shadowOffset = .zero
        } else {
            layer.shadowRadius  = 0
        }
    }
    
}
