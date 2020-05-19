//
//  UISwitchEx.swift
//  apturicovid
//
//  Created by Artjoms Spole on 19/05/2020.
//  Copyright © 2020 MAK IT. All rights reserved.
//

import UIKit

extension UISwitch {
    func setOffColor(_ color: UIColor){
        tintColor = color
        layer.cornerRadius = bounds.height / 2
        backgroundColor = color
    }
}
