//
//  PhoneTextField.swift
//  apturicovid
//
//  Created by Melānija Grunte on 17/05/2020.
//  Copyright © 2020 MAK IT. All rights reserved.
//

import Foundation
import UIKit

class PhoneTextField: UITextField {
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(UIResponderStandardEditActions.paste(_:)) {
            return false
        }
        return super.canPerformAction(action, withSender: sender)
    }
}
