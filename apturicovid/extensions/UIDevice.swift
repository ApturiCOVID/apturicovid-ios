//
//  UIDeviced.swift
//  apturicovid
//
//  Created by Melānija Grunte on 18/05/2020.
//  Copyright © 2020 MAK IT. All rights reserved.
//

import Foundation
import UIKit

extension UIDevice {
    var isIphoneSE: Bool {
        return UIScreen.main.bounds.size.height <= 568
    }
}
