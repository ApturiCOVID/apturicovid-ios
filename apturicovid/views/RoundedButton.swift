//
//  RoundedButton.swift
//  apturicovid
//
//  Created by Artjoms Spole on 13/05/2020.
//  Copyright © 2020 MAK IT. All rights reserved.
//

import UIKit

@IBDesignable class RoundedButton: UIButton {
    
    @IBInspectable var cornerRadius: CGFloat = 0.0 {
           didSet { layer.cornerRadius = cornerRadius }
       }
    
    override var isEnabled: Bool{
        didSet { alpha = isEnabled ? 1 : 0.6 }
    }
}
