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
        didSet { layer.cornerRadius = cornerRadius }
    }
    
    @IBInspectable var masksToBounds: Bool = false {
        didSet { layer.masksToBounds = masksToBounds}
    }
    
    @IBInspectable var lineWidth: CGFloat = 0.0 {
        didSet { layer.borderWidth = lineWidth }
    }
    
    @IBInspectable var lineColor: UIColor = .black {
        didSet{ layer.borderColor = lineColor.cgColor }
    }
    
    @IBInspectable var shadowRadius: CGFloat = 0 {
        didSet  { applyShadow(shadowEnabled) }
    }
    
    @IBInspectable var shadowOpacity: Float = 0 {
        didSet  { applyShadow(shadowEnabled) }
    }
    
    @IBInspectable var shadowColor: UIColor = .lightGray {
        didSet{ layer.shadowColor = shadowColor.cgColor }
    }
    
    private var shadowEnabled: Bool {shadowOpacity != 0}
    
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
