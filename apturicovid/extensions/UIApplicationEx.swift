//
//  UIApplicationEx.swift
//  apturicovid
//
//  Created by Artjoms Spole on 26/05/2020.
//  Copyright © 2020 MAK IT. All rights reserved.
//

import UIKit.UIApplication

extension UIApplication {
    
    static func openSettings(){
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
    }
    
}
