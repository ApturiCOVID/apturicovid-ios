//
//  WelcomeHeader.swift
//  apturicovid
//
//  Created by Artjoms Spole on 13/05/2020.
//  Copyright © 2020 MAK IT. All rights reserved.
//

import UIKit

@IBDesignable class WelcomeHeaderView: UIView {
    
    @IBInspectable var bottomCornerRadius: CGFloat = 0.0
    @IBInspectable var fillColor: UIColor = .white
    
    override func draw(_ rect: CGRect) {
        backgroundColor = nil
        
        let path = UIBezierPath(roundedRect: rect,
                                byRoundingCorners: [.bottomLeft,.bottomRight] ,
                                cornerRadii: CGSize(width: bottomCornerRadius,
                                                    height: bottomCornerRadius))
        
        fillColor.setFill()
        path.fill()
    }
}
